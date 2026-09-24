# main.tf

# Security Group
resource "aws_security_group" "ec2" {
  name_prefix = "${var.name_prefix}-ec2-"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ec2-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.name_prefix}-key"
  public_key = var.public_key

  tags = var.common_tags
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = var.common_tags
}

# Attach basic policies to the role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                     = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.ec2.id]
  subnet_id               = aws_subnet.public.id
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name
  disable_api_termination = var.enable_termination_protection

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = true # ensure encrypted at rest
    delete_on_termination = true
  }

  user_data = base64encode(var.user_data) # we set user data cloud init script that automatically updates packages on instance when starting up

  metadata_options {
    http_endpoint = "enabled" ## important: sets ec2 instance metadata service
    http_tokens   = "required" ## important: ensures metadata service v2 which protects against SSRF
    http_put_response_hop_limit = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize as needed

# name_prefix = "my-web-server"
# instance_type = "t3.small"
# create_key_pair = true
# public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-public-key"
# allowed_ssh_cidrs = ["YOUR_IP/32"]
# enable_termination_protection = true
# create_additional_volume = true

# common_tags = {
#   Environment = "production"
#   Project     = "web-app"
#   Owner       = "team-alpha"
#   ManagedBy   = "terraform"
# }
