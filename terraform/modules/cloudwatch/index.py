import json
import boto3
import time
client = boto3.client('ec2')

def lambda_handler(event, context):
   print(f'boto3 version: {event}')
   instanceID= event['detail']['EC2InstanceId']

   print(instanceID)
   custom_name = f"cassandra-node-{instanceID[:8]}"

   client.create_tags(
        Resources=[instanceID],
        Tags=[
            {
                'Key': 'Name',
                'Value': custom_name
            }
        ]
    )