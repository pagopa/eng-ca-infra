import re
from os import environ

import boto3
import botocore.client
from flask import current_app, request
from werkzeug.exceptions import BadRequest, Unauthorized


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
def publish_to_sns(msg):
    HTTP_CLIENT_INTERNAL_TIMEOUT = 3
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
