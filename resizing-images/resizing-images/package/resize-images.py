import boto3
from PIL import Image
import os

def lambda_handler(event, context):
    source_bucket    = event['Records'][0]['s3']['bucket']['name']
    thumbnail_bucket = os.environ['THUMBNAIL_BUCKET']
    key              = event['Records'][0]['s3']['object']['key']
    width            = int(os.environ['THUMBNAIL_WIDTH'])
    height           = int(os.environ['THUMBNAIL_HEIGHT'])

    s3 = boto3.client('s3')
    s3.download_file(source_bucket, key, '/tmp/' + key)

    try:
        with Image.open('/tmp/' + key) as im:
            outfile = os.path.splitext(key)[0] + ".thumbnail." + im.format
            im.thumbnail((width, height))
            im.save('/tmp/' + outfile, im.format)
    except IOError as e:
        print("Error creating thumbnail for", img, e)

    s3.upload_file('/tmp/' + outfile, thumbnail_bucket, outfile)
