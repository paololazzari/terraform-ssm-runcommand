locals {
  # Determine whether the operating system is Windows or Unix based on the home dir path
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  is_unix    = substr(pathexpand("~"), 0, 1) == "/" ? true : false

  # Sanitize command provided by user
  ssm_command_win  = "\"${replace("${var.command}", "$", "`$")}\""
  ssm_command_unix = "\"${replace("${var.command}", "$", "\\$")}\""
  ssm_command      = local.is_windows ? local.ssm_command_win : local.ssm_command_unix

  # Format the command to feed to the script
  args = join(" ", [
    "${var.instance_id}",
    "${var.target_os}",
    local.ssm_command,
    "${var.wait_for_command_completion}",
    "${var.ssm_timeout_seconds}",
    "${var.show_command_output}",
    "${var.continue_on_error}",
    "${var.timeout_seconds}",
    "\"${var.comment}\"",
    "\"${var.output_s3_bucket_name}\"",
    "${var.output_s3_key_prefix}",
    "${var.service_role_arn}",
    "${var.notification_config}",
    "${var.cloud_watch_output_config}",
    "${var.alarm_configuration}",
    "${var.endpoint_url}",
    "${var.region}"
  ])

  # If a log file was specified, prepare the redirect
  log_redirect = var.log_file == "\"\"" ? "" : "> ${var.log_file}"

  # Format the local-exec command
  ssm_runcommand_command = (
    local.is_windows ?
    "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted; & util\\ssm_run_command.ps1" :
    "bash util/ssm_run_command.sh"
  )
}

resource "null_resource" "ssm_runcommand_provisioner" {

  # Run the ssm_run_command script with the specified options
  provisioner "local-exec" {

    command     = "${local.ssm_runcommand_command} ${local.args} ${local.log_redirect}"
    interpreter = local.is_windows ? ["Powershell"] : []
    working_dir = path.module
  }
}
