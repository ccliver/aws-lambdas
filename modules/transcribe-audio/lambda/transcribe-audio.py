import boto3
import os

def lambda_handler(event, context):
    bucket = os.environ['S3_BUCKET']
    key = event['Records'][0]['s3']['object']['key']


    transcribe = boto3.client('transcribe')
    response = transcribe.start_transcription_job(
        TranscriptionJobName=key,
        LanguageCode='en-US',
        MediaFormat=key.split('.')[1],
        Media={
            'MediaFileUri': "s3://{}/{}".format(bucket, key)
        }
    )
