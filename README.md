[//]: # "Cool Github integration tags courtesy of the BridgeCrew integration"
[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/han-lon/basic-terraform-example/hipaa)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=Han-Lon%2Fbasic-terraform-example&benchmark=HIPAA)

[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/han-lon/basic-terraform-example/nist)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=Han-Lon%2Fbasic-terraform-example&benchmark=NIST-800-53)

[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/han-lon/basic-terraform-example/pci)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=Han-Lon%2Fbasic-terraform-example&benchmark=PCI-DSS+V3.2)

[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/han-lon/basic-terraform-example/general)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=Han-Lon%2Fbasic-terraform-example&benchmark=INFRASTRUCTURE+SECURITY)

# basic-terraform-example
Launches a new VPC, 2 public subnets, 2 internal subnets, 2 EC2 instances running RedHat, and an ALB directing traffic to one instance

<b> I set up the project in a similar way to how I'd do it in an enterprise environment (dev/test/prod folder structure with matching
main.tf files and environment-specific values within each _input.tfvars file) However, since
I only have 1 personal AWS account, each environment will deploy the same resources to the same account-- the only difference being the
ENVIRONMENT variable in each _input.tfvars file </b>

