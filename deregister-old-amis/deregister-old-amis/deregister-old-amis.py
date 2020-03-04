import boto3
import os
import datetime
from dateutil.parser import parse

def days_old(date):
    parsed = parse(date).replace(tzinfo=None)
    diff = datetime.datetime.now() - parsed
    return diff.days

def deregister_amis(account_id):
    """Find AMIs with the AMI_TAG tag and if they are older than MAX_DAYS deregister them."""

    tag = os.getenv('AMI_TAG')
    regions = os.getenv('AWS_REGIONS')
    max_days = os.getenv('MAX_DAYS')

    for region in regions.split(','):
        ec2 = boto3.resource('ec2', region_name=region)
        for image in ec2.images.filter(Filters=[{'Name': 'owner-id', 'Values': [account_id]}, {'Name': 'tag-key', 'Values': [tag]}]):
            image_days_old = days_old(image.creation_date)
            print("Image {}, CreationDate: {} ({} days old)".format(image.id, image.creation_date, image_days_old))

            if image_days_old >= int(max_days):
                print("Deregistering AMI {}".format(image.id))
                image.deregister()

def lambda_handler(event, context):
    deregister_amis(context.invoked_function_arn.split(':')[4])

if __name__ == '__main__':
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    deregister_amis(account_id)
