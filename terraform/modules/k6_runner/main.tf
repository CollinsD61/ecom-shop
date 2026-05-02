# =============================================================================
# Module: k6_runner
# =============================================================================
# Tao 1 EC2 nam trong public subnet cua VPC de chay spike test vao EKS cluster.
# - AMI: Amazon Linux 2023
# - Cai dat tu dong: k6, git, jq bang user_data
# - Truy cap bang SSM Session Manager (khong can mo port 22)
# - SSH key pair optional — truyen var.key_name de SSH truc tiep
# =============================================================================

# -----------------------------------------------------------------------------
# Data: lay AMI Amazon Linux 2023 moi nhat
# -----------------------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Security Group — cho phep outbound + SSH optional
# -----------------------------------------------------------------------------
resource "aws_security_group" "k6_runner" {
  name        = "${var.env}-k6-runner-sg"
  description = "Security group for k6 load testing EC2"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidr) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr
      description = "SSH from allowed CIDRs"
    }
  }

  tags = {
    Name        = "${var.env}-k6-runner-sg"
    Environment = var.env
    Role        = "k6-load-tester"
  }
}

# -----------------------------------------------------------------------------
# IAM Role — cho phep SSM Session Manager
# -----------------------------------------------------------------------------
resource "aws_iam_role" "k6_runner" {
  name = "${var.env}-k6-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.env}-k6-runner-role"
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.k6_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k6_runner" {
  name = "${var.env}-k6-runner-profile"
  role = aws_iam_role.k6_runner.name
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "k6_runner" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.k6_runner.id]
  iam_instance_profile        = aws_iam_instance_profile.k6_runner.name
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Dung file() thay vi heredoc de tranh xung dot giua HCL va bash/JS syntax
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name        = "${var.env}-k6-runner"
    Environment = var.env
    Role        = "k6-load-tester"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
