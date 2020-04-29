import boto3
import os
import time

def dynamodb_backup():
    """Createa a backup of DYNAMODB_TABLE"""

    tables = os.getenv('DYNAMODB_TABLES')
    if not tables:
        raise ValueError("DYNAMODB_TABLES must be set to a comma-separated list of tables to back up")

    for table in tables.split(','):
        backupName = "%s-%s" % (table, str(int(time.time())))
        client = boto3.client('dynamodb')
        response = client.create_backup(
            TableName = table,
            BackupName = backupName
        )

        print(response)

def lambda_handler(event, context):
    dynamodb_backup()
