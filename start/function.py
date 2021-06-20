import boto3
import logging
import os

region = os.environ['AWS_REGION']
ec2 = boto3.client('ec2', region_name=region)

instances = ['i-ABC', 'i-XYZ']

def lambda_handler(event, context):
  try:
    ec2.start_instances(InstanceIds=instances)
    print('Started your instances: ' + str(instances))
  except Exception as error:
    logging.error(error)
