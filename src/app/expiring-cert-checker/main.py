import datetime
import json
import logging
import os

import boto3
import botocore.config

# use this value for timeout
HTTP_TIMEOUT = 3  # in seconds
BOTO3_CONFIG_TIMEOUT = botocore.client.Config(
    connect_timeout=HTTP_TIMEOUT,
    read_timeout=HTTP_TIMEOUT
)

# logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create a DynamoDB client outside the handler function
# for cold start mitigation purposes.
dynamodb = boto3.resource(
        'dynamodb',
        config=BOTO3_CONFIG_TIMEOUT,
        region_name=os.getenv("AWS_REGION")
    )

#Create an SNS client for the same purposes as above
sns = boto3.client(
        'sns',
        config=BOTO3_CONFIG_TIMEOUT,
        region_name=os.getenv("AWS_REGION")
    )

def publish_to_sns(msg):
    """Simple method that use the sns client to publish a message"""
    logger.info("publish to sns")
    sns.publish(TopicArn=os.getenv("AWS_SNS_TOPIC"), Message=msg)


def handler(_event, _context):
    """Lambda handler method that check if a certificate is expiring"""
    logger.info("handler started")
    # an email reminder notification will be sent if exp date is before
    default_days_interval = 7

    # Intermediates enabled
    intermediates_config = [
        ("01", default_days_interval),
        ("04", default_days_interval),
        ("05", default_days_interval)
    ]

    # perform a query on the table...
    table = dynamodb.Table(os.getenv("AWS_DYNAMODB_TABLE"))

    # ... for each intermediate ...
    for intermediate_config in intermediates_config:

        # ... get the config
        intermediate = intermediate_config[0]
        days_interval = intermediate_config[1]

        # get a unix time of the "future"
        time_delta = datetime.timedelta(days=days_interval)
        time_now = datetime.datetime.now().replace(microsecond=0)
        future_timestamp = int((time_now + time_delta).timestamp())

        # ... using the secondary index
        response = table.query(
            IndexName=os.getenv("AWS_DYNAMODB_TABLE_SECONDARY_INDEX"),
            # we are hardcoding here a bit of the schema
            # intermediate -> string value for the intermediate id
            # expiration -> integer value as an unix time
            KeyConditionExpression=boto3.dynamodb.conditions.Key("INT").eq(intermediate) &
            boto3.dynamodb.conditions.Key("NVA").lt(future_timestamp)
        )
        # just call the SNS topic with the "reminder" event type
        # if successful, the notification handler will remove the list
        for item in response["Items"]:
            try:
                send_email_flag = item["OTHER"]["SEF"]
            except KeyError:
                # the ["OTHER"]["SEF"] field was added later in DynamoDB, handle back-compatibility
                send_email_flag = False
            publish_to_sns(
                json.dumps({
                    "event": "REMINDER",
                    "data": {
                        "SEF": send_email_flag,
                        "certificate": {
                            "INT": item["INT"],
                            "SUB": item["OTHER"]["SUB"],
                            "EKU": item["OTHER"]["EKU"],
                            "SAN": item["OTHER"]["SAN"],
                            "NVB": item["OTHER"]["NVB"],
                            # NVA is expected in isoformat for pretty-printing
                            "NVA": datetime.datetime.fromtimestamp(item["NVA"])
                            .isoformat(" ", "seconds"),
                            "SER": item["SER"],
                            "TEA": item["OTHER"]["TEA"]
                        }
                    }
                })
            )
