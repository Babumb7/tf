terraform {
  backend "s3" {
    bucket         = "pw-s3-terraform-backend"
    key            = "dev/infra-microservices/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pw_dynamodb_terraform_statelock"
    encrypt        = true
  }
}