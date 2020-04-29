provider "aws" {
  region = "us-east-1"
}

module "csv-import-to-dynamodb" {
  source = "../modules/csv-import-to-dynamodb"

  source_bucket_prefix = "incoming-csv-files"
}
