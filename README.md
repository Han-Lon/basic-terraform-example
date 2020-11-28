# basic-terraform-example
Launches a new VPC, 2 public subnets, 2 internal subnets, 2 EC2 instances running RedHat, and an ALB directing traffic to one instance

<b> I set up the project in a similar way to how I'd do it in an enterprise environment (dev/test/prod folder structure with matching
main.tf files and environment-specific values within each _input.tfvars file) However, since
I only have 1 personal AWS account, each environment will deploy the same resources to the same account-- the only difference being the
ENVIRONMENT variable in each _input.tfvars file </b>
