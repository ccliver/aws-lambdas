#!/usr/bin/env python3
import argparse
from time import sleep
import boto3
from faker import Faker

parser = argparse.ArgumentParser()
parser.add_argument("--queue-name", "-q", required=True,
                    help="SQS queue name")
parser.add_argument("--interval", "-i", required=True,
                    help="timer interval", type=float)
parser.add_argument("--message", "-m", help="message to send")
args = parser.parse_args()

sqs = boto3.client('sqs')
response = sqs.get_queue_url(QueueName=args.queue_name)
queue_url = response['QueueUrl']
print(f"Found {queue_url}")

while True:
    message = args.message
    if not args.message:
        fake = Faker()
        message = fake.text()

    print(f"Sending message: {message}")
    response = sqs.send_message(
        QueueUrl=queue_url, MessageBody=message)

    print('MessageId: ' + response['MessageId'])
    sleep(args.interval)
