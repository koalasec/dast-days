# variables.tf
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "my-ec2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID to use for the instance (leave empty for latest Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "create_additional_volume" {
  description = "Whether to create an additional EBS volume"
  type        = bool
  default     = false
}

variable "additional_volume_size" {
  description = "Size of additional volume in GB"
  type        = number
  default     = 100
}

variable "additional_volume_type" {
  description = "Type of additional volume"
  type        = string
  default     = "gp3"
}

variable "enable_termination_protection" {
  description = "Enable termination protection for the instance"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
    EOF
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "ec2-module"
    ManagedBy   = "terraform"
  }
}
