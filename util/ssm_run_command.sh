#!/bin/bash
instance_id=$1
target_os=$2
command=$3
wait_for_command_completion=$4
ssm_timeout_seconds=$5
show_command_output=$6
continue_on_error=$7
timeout_seconds=$8
comment=$9
output_s3_bucket_name=${10}
output_s3_key_prefix=${11}
service_role_arn=${12}
notification_config=${13}
cloud_watch_output_config=${14}
alarm_configuration=${15}
endpoint_url=${16}
region=${17}

[ -z "$1" ] && echo "instance_id is missing" && exit 1
[ -z "$2" ] && echo "target_os is missing" && exit 1
[ -z "$3" ] && echo "command is missing" && exit 1
[ -z "$4" ] && echo "wait_for_command_completion is missing" && exit 1
[ -z "$5" ] && echo "ssm_timeout_seconds is missing" && exit 1

# Validate configuration
validate () {
    # Validate AWS CLI installation
    aws --version >/dev/null 2>&1
    if [[ "$?" -ne 0 ]]; then
        echo "AWS CLI was not found"
        exit 1
    fi
}

# Build a string for extra arguments to pass to send-command api
build_extra_args() {
    extra_args=""

    declare -A extra_args_map=( 
        ["timeout-seconds"]="$timeout_seconds"
        ["comment"]="$comment"
        ["output-s3-bucket-name"]="$output_s3_bucket_name"
        ["output-s3-key-prefix"]="$output_s3_key_prefix"
        ["service-role-arn"]="$service_role_arn"
        ["notification-config"]="$notification_config"
        ["cloud-watch-output-config"]="$cloud_watch_output_config"
        ["alarm-configuration"]="$alarm_configuration"
        ["endpoint-url"]="$endpoint_url"
        ["region"]="$region"
    )

    for arg in "${!extra_args_map[@]}"; do
        if [ -n "${extra_args_map[$arg]}" ]; then
            extra_args="${extra_args} --$arg ${extra_args_map[$arg]}"
        fi
    done

    printf "%s" "$extra_args"
}

# Helper function for send-command requests
send_command () {
    # Choose the SSM document to run based on the OS of the target instance
    if [ "$target_os" == "windows" ]; then
        document_name="AWS-RunPowerShellScript"
    else
        document_name="AWS-RunShellScript"
    fi

    # Sanitize command
    sanitized_command=$(printf "%s" "$1" | sed 's/\$/\\$/g' | sed s/\'/"\\\'"/g)

    # Execute SSM command on target instance
    ssm_command="aws ssm send-command --instance-id $instance_id --document-name $document_name --parameters commands=\"'$sanitized_command'\" --query 'Command.CommandId' --output text $2"
    ssm_command_id=$(eval "$ssm_command" 2>&1)
    ssm_command_exit_code="$?"
    echo "$ssm_command_id"
    return "$ssm_command_exit_code"
}

# Wait for SSM to be up and running on the target EC2 instance
wait_ssm_bootstrap () {
    INSTANCE_STATE_ERR=$(cat <<-END
The instance is in an invalid state.
This can occur if:

- The instance ID is not valid
- The instance is not in the selected region
- The instance is not running
- The instance does not have the SSM agent running
- The instance does not have an instance profile with sufficient SSM permissions
END
)

  # Wait for SSM to be up and running for a duration defined by the user
  ssm_healthcheck_attempts=0
  ssm_healthcheck_max_attempts=$(expr "$ssm_timeout_seconds" / 10)

  while [[ "$ssm_healthcheck_attempts" -ne "$ssm_healthcheck_max_attempts" ]]
  do
    echo "Waiting for SSM to come online on instance $instance_id"
    ssm_command_output=$(send_command "ls" 2>&1)
    ssm_command_exit_code=$?
    if [[ "$ssm_command_exit_code" -eq 0 ]]; then
      echo "SSM is online on instance $instance_id"
      return
    else
      sleep 10
      ssm_healthcheck_attempts=$[$ssm_healthcheck_attempts +1]
    fi
  done

  echo "SSM did not come online in the specified time"
  
  # If the instance is not in a valid state, exit with a helpful message
  grep -qE "Instances .* not in a valid state" <<< "$ssm_command_output"
  if [[ "$?" -eq 0 ]]; then
    echo "$INSTANCE_STATE_ERR"
    exit 1
  else
    echo "Something went wrong."
    echo "$ssm_command_output"
    exit 1
  fi
}

# Run SSM command on the target EC2 instance
run_command () {
    # Get extra args
    extra_args=$(build_extra_args)

    # Execute command and make sure a valid command id is returned
    ssm_command_command_id=$(send_command "$command" "$extra_args")
    grep -qE "^[a-z0-9-]+$" <<< "$ssm_command_command_id"
    
    if [[ "$?" -ne 0 ]]; then
      echo "Something went wrong."
      echo "Output: $ssm_command_command_id"
      exit 1
    fi

    # If wait_for_command_completion is false, exit immediately
    if [ "$wait_for_command_completion" == "false" ]; then
      echo "SSM command has been executed"
      exit 0
    fi

    # If a different region was specified, include it when retrieving ssm command details
    if [ -n "${extra_args_map[region]}" ]; then
      region_arg="--region ${extra_args_map[region]}"
    fi

    # After the command has been executed, wait for its completion
    while true
    do
        ssm_get_command_invocation_stdout_command="aws ssm get-command-invocation --instance-id $instance_id --command-id $ssm_command_command_id --query 'StandardOutputContent' --output text $region_arg"
        ssm_get_command_invocation_stderr_command="aws ssm get-command-invocation --instance-id $instance_id --command-id $ssm_command_command_id --query 'StandardErrorContent' --output text $region_arg"
        ssm_command_invocation_stdout=$(eval $ssm_get_command_invocation_stdout_command)
        ssm_command_invocation_stderr=$(eval $ssm_get_command_invocation_stderr_command)

        if [[ "$ssm_command_invocation_stdout" == "" && "$ssm_command_invocation_stderr" == "" ]]; then
            : # If both STDOUT and STDERR are empty, then the command has not completed yet
        else
            if [[ "$ssm_command_invocation_stdout" != "" && "$show_command_output" == "true" ]]; then
                echo "SSM command standard output: $ssm_command_invocation_stdout"
            fi
            if [ -n "$ssm_command_invocation_stderr" ]; then
                if [ "$show_command_output" == "true" ]; then
                    echo "$ssm_command_invocation_stderr"
                fi

                if [ "$continue_on_error" == "false" ]; then
                    echo "SSM command execution had errors"
                    exit 1
                fi
            fi
            exit 0
        fi
    done
}

# Validate configuration
validate

# Wait for SSM to be up and running on target instance
wait_ssm_bootstrap

# Run SSM command on target instance
run_command