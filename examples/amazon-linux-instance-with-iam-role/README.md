# Amazon Linux instance with IAM role

This example shows how the ssm_runcommand module can be used to execute commands on an Amazon Linux EC2 instance via AWS SSM.

## Usage

To run this example, execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

To inspect the output:

```bash
$ cat .\ssm_runcommand_linux_example_1.log
Waiting for SSM to come online on instance i-0e8bc59c524242e6c
SSM is online on instance i-0e8bc59c524242e6c
SSM command standard output: root
```

```bash
$ cat .\ssm_runcommand_linux_example_2.log 
Waiting for SSM to come online on instance i-0e8bc59c524242e6c
SSM is online on instance i-0e8bc59c524242e6c
SSM command standard output:  2207 ?        Ssl    0:00 /usr/bin/amazon-ssm-agent
 2582 ?        S      0:00 sh -c /var/lib/amazon/ssm/i-0e8bc59c524242e6c/document/orchestration/04c204c6-1bbe-4c73-b059-c552ef9d7b7b/awsrunShellScript/0.awsrunShellScript/_script.sh
 2584 ?        R      0:00 sh -c /var/lib/amazon/ssm/i-0e8bc59c524242e6c/document/orchestration/04c204c6-1bbe-4c73-b059-c552ef9d7b7b/awsrunShellScript/0.awsrunShellScript/_script.sh
```

```bash
$ cat .\ssm_runcommand_linux_example_3.log
Waiting for SSM to come online on instance i-0e8bc59c524242e6c
SSM is online on instance i-0e8bc59c524242e6c
SSM command standard output: /usr/bin
```

To destroy this example, execute:

```bash
$ terraform destroy
```

This example creates resources which can cost money (AWS EC2 instance, for example). Run `terraform destroy` when you don't need these resources.

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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ssm_runcommand"></a> [ssm_runcommand](#module\_ssm_runcommand) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.amazon_linux_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami) | data source |
| [aws_instance.amazon_linux_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_instance) | resource |
| [aws_iam_instance_profile.amazon_linux_instance_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.amazon_linux_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |

## Inputs

No inputs.

## Outputs

No outputs.