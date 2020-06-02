provider "aws" {
  region = "us-east-1"
}

module "detect-faces" {
  source = "../modules/detect-faces"

  source_bucket_prefix = "images"
  faces_table_name     = "faces-from-images"
}
