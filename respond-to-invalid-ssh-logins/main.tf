provider "aws" {
  region = "us-east-1"
}

module "respond-to-invalid-ssh-logins" {
  source = "../modules/respond-to-invalid-ssh-logins"

  region = "us-east-1"
}
