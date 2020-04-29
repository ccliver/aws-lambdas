#!/usr/bin/env python3

import os
import csv
import boto3

def import_into_dynamodb(csv_file):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])

    with table.batch_writer() as batch:
        with open(csv_file) as csvfile:
            movies = csv.reader(csvfile, delimiter=',')
            next(movies, None) # skip header

            for movie in movies:
                movie = ['NA' if column == '' else column for column in movie]

                batch.put_item(
                    Item={
                        'Year': int(movie[0]),
                        'Title': movie[2],
                        'Meta': {
                            'Length': movie[1],
                            'Subject': movie[3],
                            'Actor': movie[4],
                            'Actress': movie[5],
                            'Director': movie[6],
                            'Popularity': movie[7],
                            'Awards': movie[8],
                            'Image': movie[9]
                        }
                    }
                )

def lambda_handler(event, context):
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    s3 = boto3.client('s3')
    s3.download_file(source_bucket, key, '/tmp/' + key)
    import_into_dynamodb('/tmp/' + key)
