variable "instance_id" {
  description = "The id of the EC2 instance on which to run the SSM command"
  validation {
    condition     = can(regex("i-(?:[a-z0-9]{8}|[a-z0-9]{17})", var.instance_id))
    error_message = "Invalid instance id"
  }
}

variable "target_os" {
  description = "The operating system of the EC2 instance on which to run the SSM command"
  validation {
    condition     = can(regex("^(windows|unix)$", var.target_os))
    error_message = "Invalid input; target_os must be either \"windows\" or \"unix\""
  }
}

variable "command" {
  description = "The command to execute on the EC2 instance"
}

variable "wait_for_command_completion" {
  default     = false
  description = "Whether or not the terraform execution should wait for the SSM command to be completed"
  validation {
    condition     = contains([true, false], var.wait_for_command_completion)
    error_message = "Invalid input; wait_for_command_completion must be either \"true\" or \"false\""
  }
}

variable "ssm_timeout_seconds" {
  description = "How many seconds the SSM agent has to start before the instance is deemed unhealthy"
  default     = 60
  validation {
    condition     = can(regex("^[1-9]\\d*(\\.\\d+)?$", var.ssm_timeout_seconds))
    error_message = "Invalid input; ssm_timeout_seconds must be a valid number"
  }
}

variable "show_command_output" {
  default     = false
  description = "Whether or not the output of the SSM command should be printed"
  validation {
    condition     = contains([true, false], var.show_command_output)
    error_message = "Invalid input; show_command_output must be either \"true\" or \"false\""
  }
}

variable "continue_on_error" {
  default     = false
  description = "Whether or not the terraform execution should continue if the SSM command failed"
  validation {
    condition     = contains([true, false], var.continue_on_error)
    error_message = "Invalid input; continue_on_error must be either \"true\" or \"false\""
  }
}

variable "log_file" {
  default     = "\"\""
  description = "If specified, any outputs will be redirected to it"
}

variable "timeout_seconds" {
  default     = "\"\""
  description = "If this time is reached and the command hasn't already started running, it won't run"
  validation {
    condition     = can(regex("\"\"|^([3-9]\\d|\\d{3,})$", var.timeout_seconds))
    error_message = "Invalid input; timeout_seconds must be whole positive integer greater than 30"
  }
}

variable "comment" {
  default     = "\"\""
  description = "User-specified information about the command, such as a brief description of what the command should do"
}

variable "output_s3_bucket_name" {
  default     = "\"\""
  description = "The name of the S3 bucket where command execution responses should be stored"
  validation {
    condition     = can(regex("\"\"|^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.output_s3_bucket_name))
    error_message = "Invalid input; timeout_seconds must be whole positive integer greater than 30"
  }
}

variable "output_s3_key_prefix" {
  default     = "\"\""
  description = "The directory structure within the S3 bucket where the responses should be stored"
}

variable "service_role_arn" {
  default     = "\"\""
  description = "The ARN of the Identity and Access Management (IAM) service role to use to publish Amazon Simple Notification Service (Amazon SNS) notifications for Run Command commands"
  validation {
    condition     = can(regex("\"\"|^arn:aws:iam::\\d{12}.+$", var.service_role_arn))
    error_message = "Invalid input; service_role_arn must be a valid ARN"
  }
}

variable "notification_config" {
  default     = "\"\""
  description = "Configurations for sending notifications"
  validation {
    condition     = can(regex("\"\"|^NotificationArn=arn:aws:sns:[^:]+:\\d{12}:[^,]+,NotificationEvents=[^,]+,NotificationType=.+$", var.notification_config))
    error_message = "Invalid input; notification_config must be a valid configuration"
  }
}

variable "cloud_watch_output_config" {
  default     = "\"\""
  description = "Enables Amazon Web Services Systems Manager to send Run Command output to Amazon CloudWatch Logs"
  validation {
    condition     = can(regex("\"\"|^CloudWatchOutputEnabled=(?:true|false),CloudWatchLogGroupName=[a-zA-Z0-9_\\/.#-]{1,512}$", var.cloud_watch_output_config))
    error_message = "Invalid input; cloud_watch_output_config must be a valid configuration"
  }
}

variable "alarm_configuration" {
  default     = "\"\""
  description = "The CloudWatch alarm you want to apply to your command"
  validation {
    condition     = can(regex("\"\"|IgnorePollAlarmFailure=(?:true|false),Alarms=\\[{Name=.+}]", var.alarm_configuration))
    error_message = "Invalid input; alarm_configuration must be a valid configuration"
  }
}

variable "endpoint_url" {
  default     = "\"\""
  description = "Override command's default URL with the given URL"
  validation {
    condition     = can(regex("\"\"|^https?:\\/\\/.+$", var.endpoint_url))
    error_message = "Invalid input; endpoint_url must be a valid url"
  }
}

variable "region" {
  default     = "\"\""
  description = "The region to use. Overrides config/env settings"
  validation {
    condition = contains([
      "\"\"",
      "us-east-2",
      "us-east-1",
      "us-west-1",
      "us-west-2",
      "af-south-1",
      "ap-east-1",
      "ap-south-2",
      "ap-southeast-3",
      "ap-south-1",
      "ap-northeast-3",
      "ap-southeast-1",
      "ap-southeast-2",
      "ap-northeast-1",
      "ca-central-1",
      "eu-central-1",
      "eu-west-1",
      "eu-west-2",
      "eu-south-1",
      "eu-west-3",
      "eu-south-2",
      "eu-north-1",
      "eu-central-2",
      "me-south-1",
      "me-central-1",
      "sa-east-1",
      "us-gov-east-1",
      "us-gov-west-1"
    ], var.region)
    error_message = "Invalid input; region must be a valid AWS region"
  }
}

