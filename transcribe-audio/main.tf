provider "aws" {
  region = "us-east-1"
}

module "transcribe-audio" {
  source = "../modules/transcribe-audio"

  audio_bucket_prefix          = "audio-files"
  transcription_bucket_prefix  = "transcribed-files"
}
