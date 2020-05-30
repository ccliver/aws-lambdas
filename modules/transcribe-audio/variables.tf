variable "transcribe_lambda_name" {
  description = "Name of the transcription Lambda."
  default     = "transcribe-audio"
}

variable "parse_lambda_name" {
  description = "Name of the transcription parsing Lambda."
  default     = "parse-transcriptions"
}

variable "audio_bucket_prefix" {
  description = "Descriptive prefix to use for the bucket that holds audio recordings"
  default     = "audio-files"
}

variable "transcription_bucket_prefix" {
  description = "Descriptive prefix to use for the bucket that holds transcribed audio files"
  default     = "transcriptions"
}
