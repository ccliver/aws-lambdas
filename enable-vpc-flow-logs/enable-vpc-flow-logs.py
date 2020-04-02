import boto3
import json


def lambda_handler(event, context):
    vpcId = data['detail']['responseElements']['vpc']['vpcId']

    client = boto3.client('ec2')
    response = client.create_flow_logs(
    )
