import boto3
import sys
import os

def detect_faces(source_bucket, key):
    """Use AWS Rekognition to detect faces in the image passed in and store the names of detected faces in DynamoDB"""

    rekognition = boto3.client('rekognition')
    response = rekognition.recognize_celebrities(
        Image={
            'S3Object': {
                'Bucket': source_bucket,
                'Name': key
            }
        }
    )
    found_names = [ x['Name'] for x in response['CelebrityFaces'] ]
    print("Found {} in {}".format(found_names, key))

    dynamodb = boto3.client('dynamodb')
    response = dynamodb.put_item(
        TableName = os.environ['DYNAMODB_TABLE'],
        Item = {'fileName':{'S':key},'detectedFaces':{'SS':found_names}})
    print(response)

def lambda_handler(event, context):
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key           = event['Records'][0]['s3']['object']['key']

    detect_faces(source_bucket, key)


if __name__ == '__main__':
    detect_faces(sys.argv[1], sys.argv[2])
