data "aws_kms_key" "key_lab" {
  key_id = "alias/lab-key"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20241121.0-kernel-6.1-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}