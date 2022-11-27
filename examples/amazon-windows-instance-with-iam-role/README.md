# Amazon Windows instance

This example shows how the ssm_runcommand module can be used to execute commands on an Amazon Windows Server EC2 instance via AWS SSM.

## Usage

To run this example, execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

```bash
$ cat .\ssm_runcommand_windows_example_1.log
Waiting for SSM to come online on instance i-07011bb381f569c9c
SSM is online on instance i-07011bb381f569c9c
SSM command standard output:
Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    147      11    16764      10884       0.56   1944   0 amazon-ssm-agent
```

```bash
$ cat .\ssm_runcommand_windows_example_2.log 
Waiting for SSM to come online on instance i-07011bb381f569c9c
SSM is online on instance i-07011bb381f569c9c
SSM command standard output: EC2AMAZ-724O9PD$
```

```bash
$ cat .\ssm_runcommand_windows_example_3.log
Waiting for SSM to come online on instance i-07011bb381f569c9c
SSM is online on instance i-07011bb381f569c9c
SSM command standard output: Administrator
Public
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
| [aws_ami.amazon_windows_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami) | data source |
| [aws_instance.amazon_windows_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_instance) | resource |
| [aws_iam_instance_profile.amazon_windows_instance_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.amazon_windows_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |

## Inputs

No inputs.

## Outputs

No outputs.