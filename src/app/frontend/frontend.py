import datetime
import hashlib
import json
import logging
import re

from cryptography.hazmat.backends import default_backend as crypto_backend
from cryptography.x509 import load_pem_x509_certificate, load_pem_x509_csr
from cryptography.x509.extensions import ExtensionNotFound as X509ExtensionNotFound
from cryptography.x509.oid import ExtensionOID as X509ExtensionOID
from cryptography.x509.oid import NameOID as X509NameOID
from email_validator import EmailNotValidError, validate_email
from flask import Blueprint, Response, escape, jsonify, request
from werkzeug.exceptions import BadRequest, ServiceUnavailable

from .utils.config import Config, RequestType
from .utils.utils import (
    extract_client_ip,
    log,
    log_and_quit,
    make_request_to_vault,
    publish_to_sns,
    require_authorization_header,
    require_json_request_body,
)

# timeout for all requests
HTTP_CLIENT_EXTERNAL_TIMEOUT = int( Config.get_defaulted_env("HTTP_CLIENT_EXTERNAL_TIMEOUT"))
HTTP_CLIENT_INTERNAL_TIMEOUT = int( Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT"))

# DEFAULT variables support
VAULT_ADDR = "VAULT_ADDR"

# register Blueprints
v1 = Blueprint("v1_services",__name__)  # do not use current_app

# set INFO level for logging
# TODO, find a way to set to DEBUG without redeploy
logging.basicConfig(level=logging.INFO, format="(%(levelname)s) %(message)s")


@v1.route("/intermediate/<int:intermediate_id>/certificates", methods=["GET"])
def list_intermediate(intermediate_id):
    client_ip = extract_client_ip()
    token = require_authorization_header(client_ip)
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"
    # get the hash of the token for session tracking
    h_token = hashlib.sha256(bytes(token, encoding="utf-8")).hexdigest()

    resp_tuple = make_request_to_vault(intermediate_id, token, RequestType.LIST)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]

    try:
        serial_numbers = req.json()["data"]["keys"]
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    # notify all of certificate list
    log("DEBUG", client_ip, request.path,
        f"Sending a LIST event to SNS. HTK: {h_token}")
    try:
        publish_to_sns(
            json.dumps({
                "event": "LIST",
                "data": {
                    "IPA": client_ip,
                    "RAP": request.path,
                    "HTK": h_token,
                }
            })
        )
    except Exception as ex:
        log("WARNING", client_ip, request.path,
            f"""Failed to post to SNS topic ({repr(ex)})."
                "HTK: {h_token}"
            """)
    # log the successful execution of the request
    # a log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to list all certs."
                "HTK: {h_token}"
                """
    log("INFO", client_ip, request.path, log_msg)
    # return the certificate to the operator client
    return jsonify(serial_numbers=serial_numbers)


@v1.route("/intermediate/<int:intermediate_id>/certificate/<serial_number>", methods=["GET"])
def get(intermediate_id, serial_number):
    client_ip = extract_client_ip()
    token = require_authorization_header(client_ip)
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"
    # get the hash of the token for session tracking
    h_token = hashlib.sha256(bytes(token, encoding="utf-8")).hexdigest()
    regex_serial_number = "^(?:[a-f0-9]{2}-){19}[a-f0-9]{2}$"
    if not re.compile(regex_serial_number).match(serial_number):
        error_msg = "Unexpected parameter format."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)

    resp_tuple = make_request_to_vault(intermediate_id, token, RequestType.GET ,serial_number=serial_number)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]

    try:
        certificate = req.json()["data"]["certificate"]
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    # notify all of certificate read
    log("DEBUG", client_ip, request.path,
        f"Sending a READ event to SNS. HTK: {h_token}")
    try:
        publish_to_sns(
            json.dumps({
                "event": "READ",
                "data": {
                    "IPA": client_ip,
                    "RAP": request.path,
                    "HTK": h_token,
                }
            })
        )
    except Exception as ex:
        log("WARNING", client_ip, request.path,
            f"""Failed to post to SNS topic ({repr(ex)})."
                "HTK: {h_token}"
            """)
    # log the successful execution of the request
    # a log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to read a certificate."
                "SER: {serial_number}"
                "HTK: {h_token}"
            """
    log("INFO", client_ip, request.path, log_msg)
    # return the certificate to the operator client
    return jsonify(certificate=certificate)


@v1.route("/intermediate/<int:intermediate_id>/certificate", methods=["POST"])
def sign_csr(intermediate_id):
    client_ip = extract_client_ip()
    request_body = require_json_request_body(client_ip)
    token = require_authorization_header(client_ip)
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"
    # get the hash of the token for session tracking
    h_token = hashlib.sha256(bytes(token, encoding="utf-8")).hexdigest()
    try:
        # csr is mandatory
        _ = request_body["csr"]
        # ttl and email are optional fields
        if set(request_body.keys()) > set(["csr", "ttl", "email_flag"]):
            raise KeyError
    # KeyError will also be raised by valid but empty JSON
    except KeyError:
        error_msg = "Unexpected request schema."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    try:
        email_flag = bool(request_body["email_flag"])
    except KeyError:
        email_flag = False  # email_flag is an optional field
    # parse the csr parameter, must be in PEM format
    try:
        csr_raw = load_pem_x509_csr(
            bytes(request_body["csr"], encoding="utf-8"), crypto_backend())
    except ValueError:
        error_msg = "The CSR is malformed or in a different format than PEM."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    try:
        # get the email address, do a pop() as the unique element in the list
        # do not perform any lookup against SMTP or DNS MX check in validation
        csr_subj_emails = [
            validate_email(x.value).email for x in
            csr_raw.subject.get_attributes_for_oid(X509NameOID.EMAIL_ADDRESS)
        ]
    except IndexError:
        csr_subj_emails = None
    except EmailNotValidError:
        error_msg = "The email is not in a valid format"
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    # build the request
    # ASSUMPTION! no one is going to ask for ServerAuth certificates
    # some hardcoded values for a sign-verbatim call against the backend
    signing_request_body = {}
    signing_request_body["format"] = "pem"
    signing_request_body["key_usage"] = ["DigitalSignature"]
    signing_request_body["ext_key_usage"] = ["ClientAuth"]
    signing_request_body["csr"] = request_body["csr"]
    # parse the ttl field
    try:
        regex_ttl = "^[1-9][0-9]{0,4}h$"
        ttl = request_body["ttl"]
        # ASSUMPTION! no one is going to ask for > 10y certificates
        # ASSUMPTION! no one is going to ask for < 1h certificates
        # this should grant 99999h, roughly 10y
        if not re.compile(regex_ttl).match(ttl):
            error_msg = "Unexpected parameter format."
            log_and_quit(client_ip, request.path, error_msg, BadRequest)
        signing_request_body["ttl"] = request_body["ttl"]
    except KeyError:
        pass  # ttl is an optional field

    resp_tuple = make_request_to_vault(intermediate_id, token, RequestType.SIGN ,signing_request_body=signing_request_body)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]

    # everything good so far
    try:
        response_body = req.json()
        certificate = response_body["data"]["certificate"]
        serial_number = response_body["data"]["serial_number"]
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    # prepare the data that will be needed in notifications (email and Slack)
    # parse the certificate returned from the backend
    try:
        cert_raw = load_pem_x509_certificate(
            bytes(certificate, encoding="utf-8"), crypto_backend())
    except ValueError:
        error_msg = ("The X509 certificate is malformed "
                     "or in a different format than PEM.")
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    # get the subject
    cert_subj = " ".join(x.value for x in cert_raw.subject)
    # get the timestamps
    cert_nvb = cert_raw.not_valid_before.isoformat(' ', 'seconds')
    cert_nva = cert_raw.not_valid_after.isoformat(' ', 'seconds')
    # get the SAN, but catch the exception if not present
    try:
        raw_san = cert_raw.extensions.get_extension_for_oid(
            X509ExtensionOID.SUBJECT_ALTERNATIVE_NAME).value
        cert_san = " ".join(x.value for x in raw_san)
    except X509ExtensionNotFound:
        cert_san = "--"
    # get the Extended Key Usage, but catch the exception if not present
    try:
        # _name is an internal field of the ObjectIdentifier
        raw_eku = cert_raw.extensions.get_extension_for_oid(
            X509ExtensionOID.EXTENDED_KEY_USAGE).value
        cert_eku = " ".join(x._name for x in raw_eku)
    except X509ExtensionNotFound:
        cert_eku = "--"
    # notify all of CSR signing
    log("DEBUG", client_ip, request.path,
        f"Sending a SIGNATURE event to SNS. HTK: {h_token}")
    try:
        publish_to_sns(
            json.dumps({
                "event": "SIGNATURE",
                "data": {
                    "IPA": client_ip,
                    "HTK": h_token,
                    "SEF": email_flag,
                    "RAP": request.path,
                    "certificate": {
                        "SUB": escape(cert_subj),
                        "TEA": ", ".join(csr_subj_emails),
                        "INT": intermediate_id,
                        "EKU": cert_eku,
                        "SAN": escape(cert_san),
                        "NVB": cert_nvb,
                        "NVA": cert_nva,
                        "SER": serial_number
                    },
                    "attachments": [
                        ("certificate.pem", certificate)
                    ]
                }
            })
        )
    except Exception as ex:
        log("WARNING", client_ip, request.path,
            f"""Failed to post to SNS topic ({repr(ex)})."
                "HTK: {h_token}"
            """)
    # log the successful execution of the request, even if SNS delivery failed
    # a log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to sign a CSR."
            "SER: {serial_number}"
            "HTK: {h_token}"
        """
    log("INFO", client_ip, request.path, log_msg)
    # return the certificate to the operator client
    return jsonify(certificate=certificate, serial_number=serial_number)


@v1.route("/intermediate/<int:intermediate_id>/certificate/<serial_number>", methods=["DELETE"])
def revoke(intermediate_id, serial_number):
    client_ip = extract_client_ip()
    serial_number = serial_number.lower()
    request_body = {"serial_number": serial_number}
    token = require_authorization_header(client_ip)
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"
    # get the hash of the token for session tracking
    h_token = hashlib.sha256(bytes(token, encoding="utf-8")).hexdigest()
    # check the validity of send_email_flag
    try:
        request_param = request.args["email_flag"]
        send_email_flag = bool(request_param)
    except KeyError:
        send_email_flag = False
    # always do the comparison of the serial_number in lowercase
    regex_serial_number = "^(?:[a-f0-9]{2}-){19}[a-f0-9]{2}$"
    if not re.compile(regex_serial_number).match(serial_number):
        error_msg = "Unexpected parameter format."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    # read the certificate from the backend
    try:
        response_body = get(intermediate_id, serial_number)
        certificate = response_body.get_json(silent=True)["certificate"]
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    try:
        certificate_raw = load_pem_x509_certificate(
            bytes(certificate, encoding="utf-8"), crypto_backend())
    except ValueError:
        # it should never trigger this Exception
        error_msg = (
            "The X509 certificate is malformed or "
            "in a different format than PEM."
        )
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    try:
        # do not validate email, as this was already validated while signing
        cert_subj_emails = certificate_raw.subject.get_attributes_for_oid(
            X509NameOID.EMAIL_ADDRESS
        )
    except IndexError:
        # in case the email was not specified
        cert_subj_emails = None
    # TODO should the following be wrapped in an try catch?
    # get the subject
    cert_subj = " ".join(x.value for x in certificate_raw.subject)
    # get the timestamps
    cert_nvb = certificate_raw.not_valid_before.isoformat(' ', 'seconds')
    # the rest is mostly for verbose logging
    # get the SAN, but catch the exception if not present
    try:
        raw_san = certificate_raw.extensions.get_extension_for_oid(
            X509ExtensionOID.SUBJECT_ALTERNATIVE_NAME).value
        cert_san = " ".join(x.value for x in raw_san)
    except X509ExtensionNotFound:
        cert_san = "--"
    # get the Extended Key Usage, but catch the exception if not present
    try:
        # _name is an internal field of the ObjectIdentifier list
        raw_eku = certificate_raw.extensions.get_extension_for_oid(
            X509ExtensionOID.EXTENDED_KEY_USAGE).value
        cert_eku = " ".join(x._name for x in raw_eku)
    except X509ExtensionNotFound:
        cert_eku = "--"

    resp_tuple = make_request_to_vault(intermediate_id, token, RequestType.REVOKE ,request_body=request_body)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    resp = resp_tuple[0]

    # everything good so far
    try:
        rev_time_unix = resp.json()["data"]["revocation_time"]
        rev_time = datetime.datetime.fromtimestamp(
            rev_time_unix).isoformat(' ', 'seconds')
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    # notify all of certificate revocation
    log("INFO", client_ip, request.path,
        f"Sending a REVOCATION event to SNS. HTK: {h_token}")
    try:
        publish_to_sns(
            json.dumps({
                "event": "REVOCATION",
                "data": {
                    "IPA": client_ip,
                    "HTK": h_token,
                    "RAP": request.path,
                    "SEF": send_email_flag,
                    "certificate": {
                        "INT": intermediate_id,
                        "SUB": escape(cert_subj),
                        "EKU": cert_eku,
                        "SAN": escape(cert_san),
                        "NVB": cert_nvb,
                        "RAT": rev_time,
                        # sadly when saved serial is with ":" rather than "-"
                        "SER": serial_number.replace("-", ":"),
                        "TEA": ", ".join(cert_subj_emails),
                    }
                }
            })
        )
    except Exception as ex:
        log("WARNING", client_ip, request.path,
            f"""Failed to post to SNS topic ({repr(ex)})."
                "HTK: {h_token}"
            """
            )
    # log the successful execution of the request, even if SNS delivery failed
    # a verbose log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to revoke {serial_number}."
            "HTK: {h_token}"
        """
    log("INFO", client_ip, request.path, log_msg)
    # return the unix revocation time
    return jsonify(revocation_time=rev_time_unix)


@v1.route("/intermediate/<int:intermediate_id>/crl", methods=["GET"])
def get_intermediate_crl(intermediate_id):
    client_ip = extract_client_ip()
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"

    resp_tuple = make_request_to_vault(intermediate_id, "", RequestType.CRL)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]
    
    # a log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to get a CRL."
                "HTK: -"
                """
    log("INFO", client_ip, request.path, log_msg)

    #These headers must be recalculated
    excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
    headers          = [
        (k,v) for k,v in req.raw.headers.items()
        if k.lower() not in excluded_headers
    ]

    headers.append(("isBase64Encoded", True))

    response = Response(req.content, req.status_code, headers)
    return response

@v1.route("/intermediate/<int:intermediate_id>/ca", methods=["GET"])
def get_intermediate_ca(intermediate_id):
    client_ip = extract_client_ip()
    # convert intermediate_id integer to a string
    # ASSUMPTION! here we have up to 100 CA (from 0 to 99)
    intermediate_id = str(intermediate_id).zfill(2)  # 2 -> "02"

    resp_tuple = make_request_to_vault(intermediate_id, "", RequestType.CA)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]
    
    # a log message for CloudWatch logs
    log_msg = f"""{client_ip} used {request.path} API to get a CA."
                "HTK: -"
                """
    log("INFO", client_ip, request.path, log_msg)


    #These headers must be recalculated
    excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
    headers          = [
        (k,v) for k,v in req.raw.headers.items()
        if k.lower() not in excluded_headers
    ]
 
    headers.append(("isBase64Encoded", True))
 
    response = Response(req.content, req.status_code, headers)
    return response


@v1.route("/login", methods=["POST"])
def login():
    client_ip = extract_client_ip()
    request_body = require_json_request_body(client_ip)
    try:
        github_token = request_body["token"]
    # KeyError will also be raised by valid but empty JSON
    except KeyError:
        error_msg = "Unexpected request schema."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    regex_github_token = "^[a-zA-Z0-9_]+$"  # nosec
    github_token = request_body["token"]
    if not re.compile(regex_github_token).match(github_token):
        error_msg = "Unexpected parameter format."
        log_and_quit(client_ip, request.path, error_msg, BadRequest)
    # build the request

    resp_tuple = make_request_to_vault("",github_token, RequestType.LOGIN)

    if not resp_tuple[0]:
        log_and_quit(client_ip, request.path, resp_tuple[2], resp_tuple[1])
    req = resp_tuple[0]
   
    # everything good so far (200 OK), attempt to parse the response
    try:
        response_body = req.json()
        org = response_body["auth"]["metadata"]["org"]
        username = response_body["auth"]["metadata"]["username"]
        token = response_body["auth"]["client_token"]
    except KeyError:
        error_msg = "Unexpected response from the backend."
        log_and_quit(client_ip, request.path, error_msg, ServiceUnavailable)
    # everything good, get the hash of the token for session tracking in logs
    h_token = hashlib.sha256(bytes(token, encoding="utf-8")).hexdigest()
    # who logged in? prepare log msg
    log_msg = (
        f"GitHub user {org}/{username} authenticated from "
        f"{client_ip} (session tracking: {h_token})"
    )
    # notify SNS of this event
    try:
        publish_to_sns(
            json.dumps({
                "event": "LOGIN",
                "data": {
                    "IPA": client_ip,
                    "USR": username,
                    "HTK": h_token
                }
            })
        )  # publish_to_sns may raise an exception
    except Exception as ex:
        log("WARNING", "", request.path,
            f"Failed to post to SNS topic ({repr(ex)}).")
    # log the successful execution of the request, even if SNS delivery failed
    log("INFO", client_ip, request.path, log_msg)
    # return the authorization token to the client
    return jsonify(token=token)
