import boto3
import os

def change_instance_states():
    """Find instances with the EC2_TAG tag and change their state to EC2_DESIRED_STATE"""

    tag = os.getenv('EC2_TAG')
    if os.getenv('EC2_DESIRED_STATE') == 'running':
        state = 'running'
    elif os.getenv('EC2_DESIRED_STATE') == 'stopped':
        state = 'stopped'
    else:
        raise ValueError("Valid values for EC2_DESIRED_STATE are 'stopped' and 'running'")
    regions = os.getenv('AWS_REGIONS')

    for region in regions.split(','):
        ec2 = boto3.resource('ec2', region_name=region)
        for instance in ec2.instances.filter(Filters=[{'Name': 'tag-key', 'Values': [tag]}]):
            instance.stop() if state == 'stopped' else instance.start()

def lambda_handler(event, context):
    change_instance_states()
