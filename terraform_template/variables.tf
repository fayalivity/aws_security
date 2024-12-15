variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_public_1a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_public_1b_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_private_1a_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subnet_private_1b_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

variable "tag_prefix" {
  type    = string
  default = "automation-lab"
}

variable "public_key_name" {
  type    = string
  default = "lab-key"
}