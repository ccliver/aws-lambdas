import boto3
import os
import urllib.request
import json

def lambda_handler(event, context):
    bucket = os.environ['S3_BUCKET']
    job_name = event['detail']['TranscriptionJobName']

    transcribe = boto3.client('transcribe')
    response = transcribe.get_transcription_job(TranscriptionJobName=job_name)
    download_link = response['TranscriptionJob']['Transcript']['TranscriptFileUri']
    full_transcription_job = urllib.request.urlopen(download_link).read()
    transcription = json.loads(full_transcription_job)['results']['transcripts'][0]['transcript']

    try:
        with open("/tmp/{}".format(job_name), 'w') as fh:
            fh.write(transcription)
            fh.close()
        s3 = boto3.client('s3')
        s3.upload_file("/tmp/{}".format(job_name), bucket, job_name.split('.')[0])
    except IOError as e:
        print("Error writing transcript {}: {}".format(job_name, e))
