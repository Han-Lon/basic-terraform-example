#--- VARIABLES
variable "account_id" {
    type = string
    description = "The account ID of the AWS account to deploy resources into"
}
variable "vpc_cidr" {
  type = string
  description = "The CIDR block that should be assigned to the VPC in the target account"
}
variable "environment" {
  type = string
  description = "The environment of the target account. Should be dev, test, or prod"
}
variable "region" {
  type = string
  description = "The region to launch AWS resources into"
}
variable "private_subnet_ips" {
  type = list(string)
  description = "The list of private IPv4 addresses to use for the private subnets"
}
variable "public_subnet_ips" {
  type = list(string)
  description = "The list of private IPv4 addresses to use for the public subnets"
}
variable "public_ssh_key" {
  type = string
  description = "The public SSH key to use for SSHing into the two EC2 instances"
}

#--- STATEFILE
terraform {
  backend "s3" {
    bucket = "han-lon-terraform-states"
    key = "basic-terraform-example/dev/initial"
    region = "us-east-2"
  }
}

#--- RESOURCES + MODULES

# Workaround for an issue with the Terraform AWS VPC module. Refer to the below link for background
# https://github.com/hashicorp/terraform-provider-aws/issues/9989#issuecomment-548387810
provider "aws" {
  region = var.region
}

# Create the AWS VPC using the Terraform VPC module
module "vpc" {
  # Pull the module from the public Terraform module registry
  source = "terraform-aws-modules/vpc/aws"

  name = "terraform-${var.environment}-example-vpc"
  cidr = var.vpc_cidr

  # Launch in AZs a and b of the target region
  azs = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnet_ips
  public_subnets = var.public_subnet_ips

  # Need to spin up the NAT and Internet Gateways for the instance(s) in the private subnets
  enable_vpn_gateway = false
  enable_nat_gateway = true
  create_igw = true

  tags = {
    Environment = var.environment
  }
}

# The security group attached specifically to the load balancer and public EC2 instance
resource "aws_security_group" "load-balancer-sg" {
  name = "load-balancer-sg"
  description = "The security group attached to the load balancer"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "All HTTP traffic"
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get my IP address for the security group on the public instance. Appropriate for this exercise, but I would
# use a different method in an actual enterprise project (i.e. use a known list of IPs)
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# The security group on the public instance. Only allows traffic from my public IP (see above data.http block)
resource "aws_security_group" "public-instance-sg" {
  name = "public-instance-sg"
  description = "For the public instance"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "All traffic from my IP address"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    description = "All traffic outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This security group ONLY allows the load balancer security group. Attached to the EC2 instance in the private subnet
resource "aws_security_group" "private-instance-sg" {
  name = "private-instance-sg"
  description = "Only allow inbound traffic from the LB security group"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP traffic from load-balancer-sg"
    from_port = 80
    to_port = 80
    protocol = "TCP"
    # Allowing traffic based on security group ID, which is needed for public ALBs
    security_groups = [aws_security_group.load-balancer-sg.id]

  }
  ingress {
    description = "All traffic from the other PRIVATE instances/IPs (for troubleshooting)"
    from_port = 0
    to_port = 0
    protocol = "-1"
    # Allowing traffic based on security group ID and internal IPs, which is needed for public ALBs
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow outbound traffic"
    to_port = 0
    from_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.load-balancer-sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NOTE: I am importing a currently existing private key because, as per Hashicorp's documentation, using
# the tls_private_key resource is insecure as it stores the key unencrypted in the state file
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name = "ec2-instances-bootstrap"
  public_key = var.public_ssh_key
}

# The most recent RHEL AMI
data "aws_ami" "redhat-ami" {
  most_recent = true

  owners = ["309956199498"]

  filter {
    name = "name"
    values = ["RHEL-8.3.0_HVM-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# The first EC2 RHEL instance, which will be launched into the first public subnet
module "ec2-1" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.environment}-RHEL-instance-1"

  # Use the most recent RHEL image
  ami = data.aws_ami.redhat-ami.image_id
  instance_type = "t2.micro"
  key_name = module.key_pair.this_key_pair_key_name

  # Don't enable enhanced monitoring
  monitoring = false
  # Use the appropriate public instance security group
  vpc_security_group_ids = [aws_security_group.public-instance-sg.id]
  # Use first public subnet
  subnet_id = module.vpc.public_subnets[0]

  root_block_device = [{
    volume_size = 20
  }]
}

module "ec2-3" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.environment}-RHEL-instance-1"

  # Use the most recent RHEL image
  ami = data.aws_ami.redhat-ami.image_id
  instance_type = "t2.micro"
  key_name = module.key_pair.this_key_pair_key_name

  # Don't enable enhanced monitoring
  monitoring = false
  # Use the appropriate public instance security group
  vpc_security_group_ids = [aws_security_group.public-instance-sg.id]
  # Use first public subnet
  subnet_id = module.vpc.public_subnets[0]

  root_block_device = [{
    volume_size = 20
  }]
}

# The second EC2 instance, which will be launched into the first private subnet
module "ec2-2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.environment}-RHEL-instance-2"

  ami = data.aws_ami.redhat-ami.image_id
  instance_type = "t2.micro"
  key_name = module.key_pair.this_key_pair_key_name

  # Don't enable enhanced monitoring
  monitoring = false
  # Use the default VPC security group
  vpc_security_group_ids = [aws_security_group.private-instance-sg.id]
  # Use the first private subnet
  subnet_id = module.vpc.private_subnets[0]

  user_data = file("apache_install.sh")

  root_block_device = [{
    volume_size = 20
  }]
}

# The load balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "terraform-example-alb"

  load_balancer_type = "application"

  # VPC/Networking setup
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.load-balancer-sg.id]


  # Target group to direct traffic
  target_groups = [
    {
      backend_protocol = "HTTP"
      backend_port = 80
      target_type = "instance"

    }
  ]

  # Listeners for traffic
  http_tcp_listeners = [
    {
      port = 80
      protocol = "HTTP"
      target_group_index = 0
    }
  ]
}

# Have to manually define the target group attachment because the AWS ALB module does not support
# target group attachment yet
resource "aws_lb_target_group_attachment" "lb-attach" {
  target_group_arn = module.alb.target_group_arns[0]
  target_id = module.ec2-2.id[0]
  port = 80
}
