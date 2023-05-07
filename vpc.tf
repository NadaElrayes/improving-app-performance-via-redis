data "aws_region" "current" {
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "challenge-vpc"
  cidr = "10.0.0.0/24"

  azs             = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b"]
  public_subnets  = ["10.0.0.0/28"]
  private_subnets = ["10.0.0.16/28", "10.0.0.32/28"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}