import boto3
import os
import logging
from datetime import datetime, timezone, timedelta 
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Read environment variables
DAYS_THRESHOLD = int(os.environ.get('DAYS_THRESHOLD', '30'))  # default to 30 days

def assume_role(role_arn):
    sts_client = boto3.client('sts')
    try:
        assumed_role = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName="LambdaSnapshotCheckSession"
        )
        return assumed_role['Credentials']
    except ClientError as e:
        logger.error(f"Failed to assume role: {e}")
        raise

def get_account_id(credentials):
    sts = boto3.client(
        'sts',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )
    return sts.get_caller_identity()['Account']

def get_old_snapshots(credentials, days_threshold):
    ec2_client = boto3.client(
        'ec2',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )

    try:
        snapshots = []
        paginator = ec2_client.get_paginator('describe_snapshots')
        page_iterator = paginator.paginate(OwnerIds=['self'])

        threshold_date = datetime.now(timezone.utc) - timedelta(days=days_threshold)

        for page in page_iterator:
            for snapshot in page['Snapshots']:
                start_time = snapshot['StartTime']
                if start_time < threshold_date:
                    snapshots.append({
                        'SnapshotId': snapshot['SnapshotId'],
                        'StartTime': str(start_time)
                    })

        return snapshots

    except ClientError as e:
        logger.error(f"Failed to describe snapshots: {e}")
        raise

def lambda_handler(event, context):
    logger.info("Starting snapshot check via Step Function trigger")
    logger.info(f"Event payload: {event}")

    role_arn = event.get("role")
    if not role_arn and "roles" in event and isinstance(event["roles"], list):
        role_arn = event["roles"][0]

    if not role_arn:
        logger.error("No role ARN provided in input payload")
        return {
            "statusCode": 400,
            "body": "Missing 'role' in payload"
        }

    logger.info(f"Assuming role: {role_arn}")
    try:
        credentials = assume_role(role_arn)
        account_id = get_account_id(credentials)
        old_snapshots = get_old_snapshots(credentials, DAYS_THRESHOLD)

        if not old_snapshots:
            logger.info(f"No old snapshots found for account {account_id}.")
        else:
            logger.info(f"Found {len(old_snapshots)} old snapshots in account {account_id}:")
            for snap in old_snapshots:
                logger.info(f"Snapshot ID: {snap['SnapshotId']}, Start Time: {snap['StartTime']} from account {account_id}")

        return {
            "statusCode": 200,
            "body": f"Completed scan for {account_id}, found {len(old_snapshots)} old snapshots"
        }

    except Exception as e:
        logger.error(f"Snapshot check failed for role {role_arn}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error: {str(e)}"
        }
