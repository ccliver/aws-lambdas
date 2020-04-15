variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "resize-images"
}

variable "source_bucket_prefix" {
  description = "Descriptive prefix to use for the source bucket name"
  default     = "source-images"
}

variable "thumbnail_bucket_prefix" {
  description = "Descriptive prefix to use for the thumbnail bucket name"
  default     = "thumbnail-images"
}
