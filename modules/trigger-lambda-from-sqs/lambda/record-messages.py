import boto3
import os
import json

def lambda_handler(event, context):
    message_id = event['Records'][0]['messageId']
    body = event['Records'][0]['body']

    dynamodb = boto3.client('dynamodb')
    response = dynamodb.put_item(
        TableName = os.environ['DYNAMODB_TABLE'],
        Item = {
            'messageId': { 'S': body }
        }
    )
    print(json.dumps(response))
