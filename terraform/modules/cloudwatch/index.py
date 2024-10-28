import boto3
import botocore

def lambda_handler(event, context):
   print(f'boto3 version: {event}')
   print(f'botocore version: {event.EC2InstanceId}')