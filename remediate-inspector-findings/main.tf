provider "aws" {
  region = "us-east-1"
}

module "remediate-inspector-findings" {
  source = "../modules/remediate-inspector-findings"

  region = "us-east-1"
}
