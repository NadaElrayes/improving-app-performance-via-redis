resource "aws_db_instance" "postgres_db" {
  allocated_storage      = 20
  identifier             = "postgres-db"
  db_name                = "mydb"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t3.micro"
  username               = local.rds_creds.username
  password               = local.rds_creds.password
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = var.rds_secrets_store
}

locals {
  rds_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow connection from app server sg"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}