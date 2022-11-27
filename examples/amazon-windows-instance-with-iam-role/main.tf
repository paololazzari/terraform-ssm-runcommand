data "aws_ami" "amazon_windows_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
}

resource "aws_instance" "amazon_windows_instance" {
  ami                  = data.aws_ami.amazon_windows_ami.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.amazon_windows_instance_instance_profile.name
}


resource "aws_iam_instance_profile" "amazon_windows_instance_instance_profile" {
  name = "amazon_windows_instance_instance_profile"
  role = aws_iam_role.amazon_windows_instance_role.name
}

resource "aws_iam_role" "amazon_windows_instance_role" {
  name = "amazon_windows_instance_role"
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

module "ssm_runcommand_windows_example_1" {
  source = "../../../ssm_runcommand_module"
  # The following parameters are required:
  instance_id = aws_instance.amazon_windows_instance.id
  target_os   = "windows"
  command     = "Get-Process -name 'amazon*'"
  # The following parameters are optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_windows_example_1.log"
}

module "ssm_runcommand_windows_example_2" {
  source = "../../../ssm_runcommand_module"
  # The following parameters required:
  instance_id = aws_instance.amazon_windows_instance.id
  target_os   = "windows"
  command     = "Write-Output $env:UserName"
  # The following parameters optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_windows_example_2.log"
}

module "ssm_runcommand_windows_example_3" {
  source = "../../../ssm_runcommand_module"
  # The following parameters required:
  instance_id = aws_instance.amazon_windows_instance.id
  target_os   = "windows"
  command     = "Get-ChildItem 'C:\\Users\\' | ForEach-Object { echo $_.Name }"
  # The following parameters optional:
  show_command_output         = true
  wait_for_command_completion = true
  log_file                    = "${path.cwd}/ssm_runcommand_windows_example_3.log"
}