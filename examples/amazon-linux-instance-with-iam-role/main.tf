data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "amazon_linux_instance" {
  ami                  = data.aws_ami.amazon_linux_ami.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.amazon_linux_instance_instance_profile.name
}

resource "aws_iam_instance_profile" "amazon_linux_instance_instance_profile" {
  name = "amazon_linux_instance_instance_profile"
  role = aws_iam_role.amazon_linux_instance_role.name
}

resource "aws_iam_role" "amazon_linux_instance_role" {
  name = "amazon_linux_instance_role"
  path = "/"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

module "ssm_runcommand_linux_example_1" {
  source = "../../../ssm_runcommand_module"
  # The following parameters are required:
  instance_id = aws_instance.amazon_linux_instance.id
  target_os   = "unix"
  command     = "whoami"
  # The following parameters are optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_linux_example_1.log"
}

module "ssm_runcommand_linux_example_2" {
  source = "../../../ssm_runcommand_module"
  # The following parameters are required:
  instance_id = aws_instance.amazon_linux_instance.id
  target_os   = "unix"
  command     = "ps -ax | grep 'amazon*'"
  # The following parameters are optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_linux_example_2.log"
}

module "ssm_runcommand_linux_example_3" {
  source = "../../../ssm_runcommand_module"
  # The following parameters are required:
  instance_id = aws_instance.amazon_linux_instance.id
  target_os   = "unix"
  command     = "echo $PWD"
  # The following parameters are optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_linux_example_3.log"
}