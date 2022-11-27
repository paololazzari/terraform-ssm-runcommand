param(
    [parameter(Position=0,Mandatory=$true)][string] $instance_id,
    [parameter(Position=1,Mandatory=$true)][string] $target_os,
    [parameter(Position=2,Mandatory=$true)][string] $command,
    [parameter(Position=3,Mandatory=$true)][string] $wait_for_command_completion="false",
    [parameter(Position=4,Mandatory=$true)][string] $ssm_timeout_seconds="",
    [parameter(Position=5,Mandatory=$false)][string] $show_command_output="false",
    [parameter(Position=6,Mandatory=$false)][string] $continue_on_error="false",
    [parameter(Position=7,Mandatory=$false)][string] $timeout_seconds="",
    [parameter(Position=8,Mandatory=$false)][string] $comment="",
    [parameter(Position=9,Mandatory=$false)][string] $output_s3_bucket_name="",
    [parameter(Position=10,Mandatory=$false)][string] $output_s3_key_prefix="",
    [parameter(Position=11,Mandatory=$false)][string] $service_role_arn="",
    [parameter(Position=12,Mandatory=$false)][string] $notification_config="",
    [parameter(Position=13,Mandatory=$false)][string] $cloud_watch_output_config="",
    [parameter(Position=14,Mandatory=$false)][string] $alarm_configuration="",
    [parameter(Position=15,Mandatory=$false)][string] $endpoint_url="",
    [parameter(Position=16,Mandatory=$false)][string] $region=""
)

$extra_args_map = @{
    "timeout-seconds" = $timeout_seconds
    "comment" = $comment
    "output-s3-bucket-name" = $output_s3_bucket_name
    "output-s3-key-prefix" = $output_s3_key_prefix
    "service-role-arn" = $service_role_arn
    "notification-config" = $notification_config
    "cloud-watch-output-config" = $cloud_watch_output_config
    "alarm-configuration" = $alarm_configuration
    "endpoint-url" = $endpoint_url
    "region" = $region
}

# Validate configuration
function validate() {
    # Validate AWS CLI installation
    aws --version 2>&1 > $null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI was not found"
    }
}

# Build a string for extra arguments to pass to send-command api
function build_extra_args() {
    $extra_args = ""

    foreach ($arg in $extra_args_map.keys)
    {
        if (![string]::IsNullorWhitespace($extra_args_map[$arg])){
            $extra_args += "--$($arg) $($extra_args_map[$arg])"
        }
    }

    return $extra_args
}

# Helper function for send-command requests
function send_command() {
    Param(
        [parameter(Position=0,Mandatory=$true)]$instance_id,
        [parameter(Position=1,Mandatory=$true)]$target_os,
        [parameter(Position=2,Mandatory=$true)]$command,
        [parameter(Position=3,Mandatory=$false)]$extra_args
    )

    # Choose the SSM document to run based on the OS of the target instance
    if ($target_os -eq "windows"){
        $document_name = "AWS-RunPowerShellScript"
    }
    else {
        $document_name = "AWS-RunShellScript"
    }

    # Sanitize command
    $sanitized_command=($command -replace "'","\'" -replace "\$","``$" -replace "\\\\'","\\\'")

    # Execute SSM command on target instance
    $ssm_command=@"
    aws ssm send-command --instance-ids $($instance_id) --document-name $($document_name) --parameters commands="'$($sanitized_command)'" --output json $($extra_args)
"@
    Invoke-Expression $ssm_command
}

# Wait for SSM to be up and running on the target EC2 instance
function wait_ssm_bootstrap() {
    Param(
    [parameter(Position=0,Mandatory=$true)]$instance_id,
    [parameter(Position=1,Mandatory=$true)]$target_os,
    [parameter(Position=2,Mandatory=$true)]$ssm_timeout_seconds
    )

    $INVALID_STATE_ERR=@"
The instance is in an invalid state.
This can occur if:

- The instance ID is not valid
- The instance is not in the selected region
- The instance is not running
- The instance does not have the SSM agent running
- The instance does not have an instance profile with sufficient SSM permissions
"@

    # Wait for SSM to be up and running for a duration defined by the user
    $ssm_healthcheck_attempts=0
    $ssm_healthcheck_max_attempts=[math]::ceiling($ssm_timeout_seconds/10)

    while ($ssm_healthcheck_attempts -ne $ssm_healthcheck_max_attempts){
        Write-Output "Waiting for SSM to come online on instance $instance_id"
        $ssm_command_output=$(send_command -instance_id "$instance_id" -target_os "$target_os" -command "ls" 2>&1)
        if ($LASTEXITCODE -eq 0){
            Write-Output "SSM is online on instance $instance_id"
            return
        }
        else {
            Start-Sleep 10
            $ssm_healthcheck_attempts++
        }
    }

    Write-Output "SSM did not come online in the specified time"

    $stderr = ($ssm_command_output | Where-Object{ $_ -is [System.Management.Automation.ErrorRecord] } | out-string)

    # If the instance is not in a valid state, exit with a helpful message
    $instance_invalid_state = $stderr -match "Instances .* not in a valid state"
    if ($instance_invalid_state -eq $true) {
        Write-Output $INVALID_STATE_ERR
        exit 1
    } else {
        Write-Output "Something went wrong."
        Write-Output $stderr
        exit 1
    }
}

# Run SSM command on the target EC2 instance
function run_command(){
    Param(
    [parameter(Position=0,Mandatory=$true)]$instance_id,
    [parameter(Position=1,Mandatory=$true)]$target_os,
    [parameter(Position=2,Mandatory=$true)]$command,
    [parameter(Position=3,Mandatory=$true)]$wait_for_command_completion,
    [parameter(Position=4,Mandatory=$true)]$show_command_output,
    [parameter(Position=5,Mandatory=$true)]$continue_on_error
    )

    # Get extra args
    $extra_args=build_extra_args

    # Execute command and make sure a valid command id is returned
    $ssm_command_command_id=(send_command -instance_id "$instance_id" -target_os "$target_os" -command "$command" -extra_args "$extra_args" | ConvertFrom-Json).Command.CommandId

    if ($ssm_command_command_id -notmatch "^[a-z0-9-]+$") {
        Write-Output "Something went wrong."
        Write-Output "Output: $ssm_command_command_id"
        exit 1
    }

    # If wait_for_command_completion is false, exit immediately
    if ($wait_for_command_completion -eq "false") {
        Write-Output "SSM command has been executed"
        exit
    }

    # If a different region was specified, include it when retrieving ssm command details
    if (![string]::IsNullorWhitespace($extra_args_map["region"])){
        $region_arg = "--region $extra_args_map['region']"
    }

    # After the command has been executed, wait for its completion
    while ($true) {
        $ssm_get_command_invocation_command=@"
        aws ssm get-command-invocation --instance-id $($instance_id) --command-id $($ssm_command_command_id) $($region_arg)
"@
        $ssm_command_invocation=$(Invoke-Expression $ssm_get_command_invocation_command | ConvertFrom-Json)
        $ssm_command_invocation_stdout=$($ssm_command_invocation.StandardOutputContent )
        $ssm_command_invocation_stderr=$($ssm_command_invocation.StandardErrorContent )

        if (($ssm_command_invocation_stdout -eq "") -and ($ssm_command_invocation_stderr -eq "")){
            # If both STDOUT and STDERR are empty, then the command has not completed yet
        }
        else {
            if (($ssm_command_invocation_stdout -ne "") -and ($show_command_output -eq "true")){
                Write-Output "SSM command standard output: $ssm_command_invocation_stdout"
            }

            if ($ssm_command_invocation_stderr -ne ""){
                if ($show_command_output -eq "true"){
                    Write-Output "SSM command standard error: $ssm_command_invocation_stderr"
                }

                if ($continue_on_error -eq "false"){
                    throw "SSM command execution had errors"
                }
            }
            exit 0
        }
    }
}

# Validate configuration
validate

# Wait for SSM to be up and running on target instance
wait_ssm_bootstrap `
 -instance_id $instance_id `
 -target_os $target_os `
 -ssm_timeout_seconds $ssm_timeout_seconds

# Run SSM command on target instance
run_command `
  -instance_id $instance_id `
  -target_os $target_os `
  -command $command `
  -wait_for_command_completion $wait_for_command_completion `
  -show_command_output $show_command_output `
  -continue_on_error $continue_on_error