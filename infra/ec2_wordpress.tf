# ── Key pair for SSH / SSM access ────────────────────────────────────────────
resource "aws_key_pair" "wp_mvp" {
  key_name   = "wp-mvp-key"
  public_key = var.wp_ec2_public_key
  tags       = { Name = "wp-mvp-key" }
}

variable "wp_ec2_public_key" {
  description = "SSH public key for the WordPress EC2 instance"
  type        = string
  default     = ""
}

# ── Security group ────────────────────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "wp_mvp" {
  name        = "wp-mvp-sg"
  description = "WordPress demo site"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (restrict to your IP in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wp-mvp-sg" }
}

# ── IAM role so SSM can connect without SSH keys ──────────────────────────────
resource "aws_iam_role" "wp_ec2_ssm" {
  name = "wp-mvp-ec2-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.wp_ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_s3" {
  role       = aws_iam_role.wp_ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "ssm_params" {
  name = "wp-mvp-ssm-params"
  role = aws_iam_role.wp_ec2_ssm.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:PutParameter", "ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:ap-south-1:748189524661:parameter/wp-platform/*"
    }]
  })
}

resource "aws_iam_instance_profile" "wp_ec2_ssm" {
  name = "wp-mvp-ec2-ssm"
  role = aws_iam_role.wp_ec2_ssm.name
}

# ── EC2 instance — Amazon Linux 2 + WordPress (free-tier t2.micro) ────────────
resource "aws_instance" "wp_mvp" {
  ami                    = "ami-096b8c8fe1aefe57f" # Amazon Linux 2 ap-south-1
  instance_type          = "t3.micro"
  key_name               = var.wp_ec2_public_key != "" ? aws_key_pair.wp_mvp.key_name : null
  vpc_security_group_ids = [aws_security_group.wp_mvp.id]
  iam_instance_profile   = aws_iam_instance_profile.wp_ec2_ssm.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = file("${path.module}/userdata_wp.sh")

  tags = { Name = "wp-mvp-site" }
}

# ── Elastic IP (stable address) ───────────────────────────────────────────────
resource "aws_eip" "wp_mvp" {
  instance = aws_instance.wp_mvp.id
  domain   = "vpc"
  tags     = { Name = "wp-mvp-eip" }
}

# ── Seed Sites table with the demo site record ────────────────────────────────
resource "aws_dynamodb_table_item" "demo_site" {
  table_name = aws_dynamodb_table.sites.name
  hash_key   = aws_dynamodb_table.sites.hash_key

  item = jsonencode({
    siteId    = { S = "demo-site-001" }
    ownerId   = { S = "system" }
    name      = { S = "Demo WordPress Site" }
    domain    = { S = aws_eip.wp_mvp.public_ip }
    status    = { S = "active" }
    createdAt = { S = "2026-06-10T00:00:00Z" }
    ec2InstanceId = { S = aws_instance.wp_mvp.id }
  })
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "wp_public_ip" {
  value = aws_eip.wp_mvp.public_ip
}

output "wp_site_url" {
  value = "http://${aws_eip.wp_mvp.public_ip}"
}

output "wp_admin_url" {
  value = "http://${aws_eip.wp_mvp.public_ip}/wp-admin"
}

output "wp_instance_id" {
  value = aws_instance.wp_mvp.id
}

output "wp_password_hint" {
  value = "Run: aws ec2 get-console-output --instance-id ${aws_instance.wp_mvp.id} --region ap-south-1 | grep -i 'application password'"
}
