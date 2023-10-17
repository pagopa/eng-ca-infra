import re
from os import environ
from typing import Optional

import boto3
import botocore.client
import requests as http_client
from flask import Request, current_app, request
from werkzeug.exceptions import BadRequest, Forbidden, ServiceUnavailable, Unauthorized
from werkzeug.urls import url_fix as url_encode_fix

from .aws_helper import AWSHelper
from .config import Config, RequestType
from .logger import logger


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
        connect_timeout=Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"),
        read_timeout=Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT")
    )
    sns = boto3.client(
        'sns',
        config=BOTO3_CONFIG_TIMEOUT,
        region_name=environ["AWS_REGION"]
    )
    sns.publish(TopicArn=environ["AWS_SNS_TOPIC"], Message=msg)


def get_vault_address() -> Optional[str]:
    """Return the host name of the Vault active node"""
    try:

        # If the environment variable is not set, check
        # the value inside the parameter store, if not present
        # retrieve the correct dns name and use it to initialize the variables
        if not Config.get_optional_env("VAULT_ACTIVE_ADDRESS"):

            ssm_client = AWSHelper.get_ssm_client(Config.get_env("AWS_REGION"))
            vault_address_ssm = AWSHelper.get_ssm_parameter(
                ssm_client,"ca.eng-vault_active_address", True )
            if vault_address_ssm:
                environ["VAULT_ACTIVE_ADDRESS"] = vault_address_ssm
                return vault_address_ssm

            vault_host_dns_list = [
                Config.get_env("VAULT_0_ADDR"),
                Config.get_env("VAULT_1_ADDR")
            ]

            resp = []
            for dns in vault_host_dns_list:
                try:
                    res =  http_client.get(
                        f'{dns}/v1/sys/health',
                        # INTERNAL_TIMEOUT as no external endpoints are called
                        timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                    )
                    resp.append((dns, res.status_code))
                except http_client.exceptions.RequestException:
                    resp.append((dns , None))

            # Initialise the variable with the dns of the vault
            # host that returned a status code 200
            active_node_dns = None
            active_node_dns_list = list((r[0] for r in resp if r[1] == 200))


            if active_node_dns_list:
                active_node_dns = active_node_dns_list[0]


            #If there is a value inside the variable set the env var and return it
            if active_node_dns:
                active_node_dns = active_node_dns if active_node_dns else " "

                environ["VAULT_ACTIVE_ADDRESS"] = active_node_dns

                AWSHelper.set_ssm_parameter(ssm_client, "ca.eng-vault_active_address", active_node_dns)
                return active_node_dns

            #Otherwise invalidate the dns related values and return None
            invalidate_vault_address()
            return None
        #Otherwise return the value inside the env vars
        return Config.get_optional_env("VAULT_ACTIVE_ADDRESS")
    except Exception:
        invalidate_vault_address()
        return None




def invalidate_vault_address():
    """ Invalidate the vault host dns environment variable and SSM parameters value"""
    environ["VAULT_ACTIVE_ADDRESS"] = ""
    ssm_client = AWSHelper.get_ssm_client(Config.get_env("AWS_REGION"))
    AWSHelper.set_ssm_parameter(ssm_client, "ca.eng-vault_active_address", " ")


def make_request_to_vault(intermediate_id:str, token:str, request_type:RequestType, **kwargs : dict) -> (Optional[Request], Optional[Exception], str ):
    """Make a request to Vault Active node and return a tuple containing:
    - the response from Vault or None if an error occurred
    - if an error occurred the Error class
    - if an error occurred a string containing the error message
    """

    for _ in range(0,int(Config.get_defaulted_env("MAX_RETRY_DNS_VALIDATION"))):

    #Try to retrieve the address of the vault active node
        vault_addr = ""
        try:
            for _ in range(0, int(Config.get_defaulted_env("MAX_RETRY_DNS_VALIDATION"))):
                vault_addr = get_vault_address()
                if vault_addr:
                    break
            else:
                raise ConnectionError("Max retry attempts exceeded when trying \
                                    to find the correct Vault address")

        except Exception as ex:
            invalidate_vault_address()
            return None , ConnectionError , "Max retry attempts to find Vault address reached"

        #TODO replace this with match/case when upgrade to python 3.10
        if request_type == RequestType.LIST:
            #region LIST

            # build the request
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_LIST_PATH").format(intermediate_id)}'
                )
            )
            try:
                # for some reason Vault expects a LIST HTTP method
                resp = http_client.request(
                    "LIST", backend_endpoint,
                    headers={"X-Vault-Token": token},
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )
            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue


            # If the node responses with a 307 status code
            # then it's not the active one, it's time to
            # refresh the value inside the variables related to the vault address
            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."

            return resp, None, ""
            #endregion

        elif request_type == RequestType.GET:
            #region GET
            # build the request
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_READ_PATH").format(intermediate_id)}'
                    f"{kwargs['serial_number']}"
                )
            )
            try:
                resp = http_client.get(
                    backend_endpoint,
                    headers={"X-Vault-Token": token},
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )
            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."

            return resp, None, ""
            #endregion

        elif request_type == RequestType.SIGN:
            #region SIGN
            backend_endpoint = url_encode_fix(
            (
                f'{vault_addr}'
                f'{Config.get_env("VAULT_SIGN_PATH").format(intermediate_id)}'
            )
            )
            try:
                # make the request
                resp = http_client.post(
                    backend_endpoint,
                    json=kwargs["signing_request_body"],
                    headers={"X-Vault-Token": token},
                    # INTERNAL_TIMEOUT as not external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )
            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."

            return resp, None, ""
            #endregion

        elif request_type == RequestType.REVOKE:
            #region REVOKE
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_REVOKE_PATH").format(intermediate_id)}'
                )
            )
            try:
                resp = http_client.post(
                    backend_endpoint,
                    json=kwargs["request_body"],
                    headers={"X-Vault-Token": token},
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )
            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."
            return resp, None, ""
            #endregion

        elif request_type == RequestType.CRL:
            #region
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_CRL_PATH").format(intermediate_id)}'
                )
            )

            try:
                resp = http_client.get(
                    backend_endpoint,
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )

            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            # If the node responses with a 307 status code
            # then it's not the active one, it's time to
            # refresh the value inside the variables related to the vault address
            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."

            return resp, None, ""

            #endregion

        elif request_type == RequestType.CA:
            #region
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_CA_PATH").format(intermediate_id)}'
                )
            )

            try:
                
                resp = http_client.get(
                    backend_endpoint,
                    # INTERNAL_TIMEOUT as no external endpoints are called
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))
                )

            except http_client.exceptions.RequestException:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            # If the node responses with a 307 status code
            # then it's not the active one, it's time to
            # refresh the value inside the variables related to the vault address
            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."

            return resp, None, ""

            #endregion

        elif request_type == RequestType.LOGIN:
            #region LOGIN
            backend_endpoint = url_encode_fix(
                (
                    f'{vault_addr}'
                    f'{Config.get_env("VAULT_LOGIN_PATH")}'
                )
            )
            try:
                resp = http_client.post(
                    backend_endpoint,
                    json={"token": token},
                    # use EXTERNAL_TIMEOUT because GitHub is called for introspection
                    timeout=int(Config.get_defaulted_env("HTTP_CLIENT_EXTERNAL_TIMEOUT"))
                )
            except http_client.exceptions.RequestException as ex:
                # Invalidate vault variables for the next for iteration
                invalidate_vault_address()
                continue

            if resp.status_code == 307:
                invalidate_vault_address()
                continue
            if resp.status_code != 200:
                # likely because of an invalid token
                return None, Forbidden, "Invalid authorization."
            return resp, None, ""
            #endregion

        
        

    return None , ConnectionError , "Max retry attempts to Vault reached"
