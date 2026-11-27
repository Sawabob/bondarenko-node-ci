variable "aws_region" {
  description = "AWS region for the EC2 instance and associated resources."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Optional Ubuntu 24.04 x86_64 AMI ID in the selected region. Null uses Canonical's public parameter."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Burstable x86_64 EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair imported by Terraform."
  type        = string
}

variable "public_key_path" {
  description = "Path relative to terraform/ for the OpenSSH public key to import."
  type        = string
}

variable "ssh_cidr" {
  description = "IPv4 CIDR allowed to SSH to the instance. Hosted GitHub runners use changing addresses."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr))
    error_message = "ssh_cidr must be a valid IPv4 CIDR."
  }
}
