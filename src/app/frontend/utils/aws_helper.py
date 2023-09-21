"""AWS interaction's dedicated Class file"""
from typing import Optional

import boto3
import botocore.client

from .config import Config
from .logger import logger

# some timeout defaults
BOTO3_CONFIG = botocore.client.Config(
    connect_timeout=float(Config.get_defaulted_env("HTTP_TIMEOUT")) / 2,
    read_timeout=float(Config.get_defaulted_env("HTTP_TIMEOUT")) / 2,
    retries={
        "total_max_attempts": int(Config.get_defaulted_env("HTTP_ATTEMPTS"))
    },
)

# AWS Clients
SSM_CLIENT = None
SNS_CLIENT = None



class AWSHelper:
    """ Class that handles all the interaction with AWS"""

#region SSM
    @staticmethod
    def get_ssm_client(region: str) -> Optional["boto3.client.ssm"]:
        """
        Retrieve ssm client
        """
        global SSM_CLIENT
        logger.debug("[utils.aws_helper.get_ssm_client]")
        if SSM_CLIENT is None:
            try:
                SSM_CLIENT = boto3.client(
                    "ssm", config=BOTO3_CONFIG, region_name=region
                )
                logger.debug("[utils.aws_helper.get_ssm_client]: client up")
                return SSM_CLIENT
            except Exception as ex:
                logger.error("[utils.aws_helper.get_ssm_client]: %s", repr(ex))
                return None
        return SSM_CLIENT

    @staticmethod
    def get_ssm_parameter(
        client: "boto3.client.ssm", key:str, decrypt:bool
    ) -> Optional[str]:
        """
        Get parameter from ssm service
        """
        logger.debug("[utils.aws_helper.get_ssm_parameter]")
        try:
            response = client.get_parameter(Name=key, WithDecryption=decrypt)
            return response["Parameter"]["Value"]
        except Exception as ex:
            logger.error("[utils.aws_helper.get_ssm_parameter]: %s", repr(ex))
            return None

    @staticmethod
    def set_ssm_parameter(client: "boto3.client.ssm", key: str, value: str):
        """
        Set the key - value in ssm service
        """
        logger.debug("[utils.aws_helper.set_ssm_parameter]")
        try:
            response = client.put_parameter(Name=key, Value=value, Type="String", Overwrite=True)
        except Exception as ex:
            logger.error("[utils.aws_helper.set_ssm_parameter]: %s", repr(ex))
            return False
        if not response:
            logger.error("[utils.aws_helper.set_ssm_parameter]: %s", "Error")
            return False
        return True

#endregion

#region SNS
    @staticmethod
    def get_sns_client(region: str) -> Optional["boto3.client.sns"]:
        """
        Retrieve sns client
        """
        global SNS_CLIENT
        logger.debug("[utils.aws_helper.get_sns_client]")
        if SNS_CLIENT is None:
            try:
                SNS_CLIENT = boto3.client(
                    "sns", config=BOTO3_CONFIG, region_name=region
                )
                logger.debug("[utils.aws_helper.get_sns_client]: client up")
                return SNS_CLIENT
            except Exception as ex:
                logger.error("[utils.aws_helper.get_sns_client]: %s", repr(ex))
                return None
        return SNS_CLIENT

    @staticmethod
    def publish_to_sns(client: "boto3.client.sns", msg) -> bool:
        """
        Publish message to sns topic
        """
        logger.debug("[utils.aws_helper.publish_to_sns]")
        try:
            client.publish(
                TopicArn=Config.get_env("AWS_SNS_TOPIC_ALERT"), Message=msg
            )
            return True
        except Exception as ex:
            logger.error("[utils.aws_helper.publish_to_sns]: %s", repr(ex))
            return False

#endregion
