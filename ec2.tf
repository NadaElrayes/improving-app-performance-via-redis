data "aws_ami" "amzn-linux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-x86_64-gp2"]
  }

}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Application Server Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH from my pc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Allow port-forwarding from my pc"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    description = "Allow outbound to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

module "ec2-app" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                   = "app-server"
  ami                    = data.aws_ami.amzn-linux2.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = templatefile("${path.module}/ec2-config.sh", { db_endpoint = aws_db_instance.postgres_db.endpoint, db_user = aws_db_instance.postgres_db.username, db_password = local.rds_creds.password, db_name = aws_db_instance.postgres_db.name, app_redis = data.local_file.app_redis.content, redis_endpoint = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address })

}

data "local_file" "app_redis" {
  filename = "${path.module}/app-redis.py"
}

data "aws_iam_policy" "ssm_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-ssm-policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.ec2_ssm_role.name
}