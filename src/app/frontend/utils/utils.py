import re
from os import environ
from typing import Optional

import boto3
import botocore.client
import requests as http_client
from flask import current_app, request
from werkzeug.exceptions import BadRequest, Unauthorized

from .aws_helper import AWSHelper
from .config import Config
from .logger import logger

HTTP_CLIENT_INTERNAL_TIMEOUT = 3

def log_and_quit(client_ip, route, error_msg, exception):
    log("WARNING", client_ip, route, error_msg)
    raise exception(error_msg)


def log(level, client_ip, route, error_msg):
    msg = "{} - {} - {}".format(client_ip, route, error_msg)
    if level == "CRITICAL":
        current_app.logger.critical(msg)  # pragma: no cover
    elif level == "ERROR":
        current_app.logger.error(msg)  # pragma: no cover
    elif level == "WARNING":
        current_app.logger.warning(msg)
    elif level == "DEBUG":
        current_app.logger.debug(msg)
    else:
        current_app.logger.info(msg)


def get_client_ip():
    header = request.headers.get("X-Forwarded-For")
    if header is not None:
        return header.split(",")[-1].lstrip()
    return ""  # else return empty string


def extract_client_ip():
    # for logging, look at XFF
    client_ip = get_client_ip()
    log("DEBUG", client_ip, f"{request.path} - {request.endpoint}",
        "in extract_client_ip")
    return client_ip


def require_json_request_body(client_ip):
    log("DEBUG", client_ip, f"{request.path} - {request.endpoint}",
        "in require_json_request")
    # check that Content-Type is application/json
    if not request.is_json:
        error_msg = "Unexpected content-type."
        log_and_quit(client_ip, request.path,
                     error_msg, BadRequest)
    # attempt JSON parsing (returns 400 BadRequest if fails)
    request_body = request.get_json()
    return request_body


def require_authorization_header(client_ip):
    log("DEBUG", client_ip, f"{request.path} - {request.endpoint}",
        "in require_authorization_header")
    # regex for the authorization bearer token
    regex_authorization = "^[0-9a-zA-Z_.-]+$"
    header = request.headers.get("Authorization")
    token = None
    if header is not None and header.find("Bearer ") == 0:
        token = header.split(" ")[1]
    if token is None:
        error_msg = "Missing authorization header."
        log_and_quit(client_ip, request.path,
                     error_msg, Unauthorized)
    if not re.compile(regex_authorization).match(token):
        error_msg = "Unexpected header format."
        log_and_quit(client_ip, request.path,
                     error_msg, BadRequest)
    return token


# may raise an exception, this is intentional
def publish_to_sns(msg): #TODO replace this with aws_helper.publish_to_sns
    
    BOTO3_CONFIG_TIMEOUT = botocore.client.Config(
        connect_timeout=HTTP_CLIENT_INTERNAL_TIMEOUT,
        read_timeout=HTTP_CLIENT_INTERNAL_TIMEOUT
    )
    sns = boto3.client(
        'sns',
        config=BOTO3_CONFIG_TIMEOUT,
        region_name=environ["AWS_REGION"]
    )
    sns.publish(TopicArn=environ["AWS_SNS_TOPIC"], Message=msg)


def _get_active_dns_from_ssm() -> Optional[str]:
        """
        Get active vault dns value from ssm service or None
        """
        ssm_client = AWSHelper.get_ssm_client(Config.get_env("AWS_REGION"))
        response = AWSHelper.get_ssm_parameter(ssm_client, "VAULT_ACTIVE_DNS_NODE", decrypt=True)

        # If the response is None or the value in SSM is empty
        if not response or not response["Parameter"]["Value"]:
            logger.error("[utils.utils.get_active_dns_from_ssm]: %s", "Error")
            return None
        return response["Parameter"]["Value"]
        

def get_vault_host_dns() -> Optional[str]:
    """Return the host name of the Vault active node"""

    # If the environment variable is not set, retrieve
    # the correct dns name and use it to initialize the variable
    if not Config.get_optional_env("VAULT_ACTIVE_DNS_NODE"):
        vault_host_dns_list = [
            Config.get_env("VAULT_1_ADDR"),
            Config.get_env("VAULT_2_ADDR")
        ]

        try:
            resp = []
            for dns in vault_host_dns_list:
            # for some reason Vault expects a LIST HTTP method
                res =  http_client.get(
                    dns,
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=HTTP_CLIENT_INTERNAL_TIMEOUT
                )
                resp.append(dns, res.status_code)
        except http_client.exceptions.RequestException:
            resp.append(dns , None)

        # Initialise the variable with the dns of the vault
        # host that returned a status code 200
        active_node_dns = (r[0] for r in resp if r[1] == 200)[0]

        #If there is a value inside the variable set the env var and return it
        if active_node_dns:
            active_node_dns = active_node_dns if active_node_dns else ""

            environ["DNS_ACTIVATE_NODE"] = active_node_dns
            ssm_client = AWSHelper.get_ssm_client(Config.get_env("AWS_REGION"))
            AWSHelper.set_ssm_parameter(ssm_client, "VAULT_ACTIVE_DNS_NODE", active_node_dns)
            return active_node_dns

        #Otherwise invalidate the dns related values and return None
        invalidate_vault_host_dns()
        return None
    #Otherwise return the value inside the env vars
    return Config.get_optional_env("VAULT_ACTIVE_DNS_NODE")



def invalidate_vault_host_dns():
    """ Invalidate the vault host dns environment variable and SSM parameters value"""
    #TODO find a clear way to do this
    environ["VAULT_ACTIVE_DNS_NODE"] = None
    ssm_client = AWSHelper.get_ssm_client(Config.get_env("AWS_REGION"))
    AWSHelper.set_ssm_parameter(ssm_client, "VAULT_ACTIVE_DNS_NODE", "")