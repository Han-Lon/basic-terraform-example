variable "account_id" {
    type = string
    description = "The account ID of the AWS account to deploy resources into"
}

#--- STATEFILE
terraform {
  backend "s3" {
    bucket = "han-lon-terraform-states"
    key = "basic-terraform-example/dev/initial"
    region = "us-east-2"
  }
}
