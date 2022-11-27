# terraform-ssm-runcommand

This terraform module can be used to execute commands on remote EC2 instances via AWS SSM.

## Description

The module uses a `null_resource` resource which executes either a bash script or a powershell script depending on the detected OS.
The scripts are wrappers around [AWS CLI send-command](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ssm/send-command.html), with some extra functionality.

## Usage

```terraform
module "ssm_runcommand_windows" {
  source                      = "github.com/paololazzari/terraform-ssm-runcommand"
  instance_id                 = "i-..."
  target_os                   = "windows"
  command                     = "Get-Process -name 'amazon*'"
}
```

```terraform
module "ssm_runcommand_unix" {
  source                      = "github.com/paololazzari/terraform-ssm-runcommand"
  instance_id                 = "i-..."
  target_os                   = "unix"
  command                     = "ps -ax | grep 'amazon*'"
}
```

For other examples, check the [examples](examples).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.20.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.20.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Resources

| Name | Type |
|------|------|
| [null.ssm_runcommand_provisioner](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Modules

No modules.

## Inputs

The following inputs are required:

| Parameter Name              | Description                                                                            | Type     | Default | Required |
| ------------------          | -----------                                                                            | -------- | ------- | -------  |
| instance_id                 | The id of the EC2 instance on which to run the SSM command                             | string   |         | Yes      |
| target_os                   | The operating system of the EC2 instance on which to run the SSM command               | string   |         | Yes      |
| command                     | The command to execute on the EC2 instance                                             | string   |         | Yes      |

The following inputs are optional and can be used to control the behavior of the module:

| Parameter Name              | Description                                                                            | Type     | Default | Required |
| ------------------          | -----------                                                                            | -------- | ------- | -------- |    
| wait_for_command_completion | Whether or not the terraform execution should wait for the SSM command to be completed | bool     | false   | No       |
| ssm_timeout_seconds         | How many seconds the SSM agent has to start before the instance is deemed unhealthy    | int      | 60      | No       |
| show_command_output         | Whether or not the output of the SSM command should be printed                         | bool     | false   | No       | 
| continue_on_error           | Whether or not the terraform execution should continue if the SSM command failed       | bool     | false   | No       |
| log_file                    | If specified, any outputs will be redirected to it                                     | string   | ""      | No       |

The following inputs are optional and can be used to specify arguments for the send-command cli request:

| Parameter Name              | Description                                                                                             | Type     | Default  | Required |
| ------------------          | -----------                                                                                             | -------- | -------- | -------- | 
| timeout_seconds             | If this time is reached and the command hasn't already started running, it won't run                    | string   | ""       | No       |
| comment                     | User-specified information about the command, such as a brief description of what the command should do | string   | ""       | No       |
| output_s3_bucket_name       | The name of the S3 bucket where command execution responses should be stored                            | string   | ""       | No       |
| output_s3_key_prefix        | The directory structure within the S3 bucket where the responses should be stored                       | string   | ""       | No       |
| service_role_arn            | The ARN of the Identity and Access Management (IAM) service role to use to publish Amazon Simple Notification Service (Amazon SNS) notifications for Run Command commands          | string | "" | No       |
| notification_config         | Configurations for sending notifications                                                                | string   | ""       | No       |
| cloud_watch_output_config   | Enables Amazon Web Services Systems Manager to send Run Command output to Amazon CloudWatch Logs        | string   | ""       | No       |
| alarm_configuration         | The CloudWatch alarm you want to apply to your command                                                  | string   | ""       | No       |
| endpoint_url                | Override command's default URL with the given URL                                                       | string   | ""       | No       |
| region                      | The region to use. Overrides config/env settings                                                        | string   | ""       | No       |

For more information, see the [official documentation page](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ssm/send-command.html).

## Outputs

No outputs.