provider "aws" {
  region = "us-east-1"
}

module "resizing-images" {
  source = "../modules/resizing-images"

  source_bucket_prefix    = "full-size-images"
  thumbnail_bucket_prefix = "thumbnail-images"
}
