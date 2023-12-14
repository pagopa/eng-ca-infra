#!/usr/bin/python3
import argparse
import getpass
import json
import re
import sys

import requests
from cryptography.hazmat.backends import default_backend as crypto_backend
from cryptography.x509 import load_pem_x509_csr
from cryptography.x509.oid import NameOID as X509NameOID

SERVER_ADDRESS = "https://api.dev.ca.eng.pagopa.it"
API_VERSION = ""
LOGIN_API = "/login"
# DELETE /intermediate/{intermediate_id}/certificate/{serial_number}
REVOKE_API = "/intermediate{}/certificate/{}"
# POST /intermediate/{intermediate_id}/certificate
SIGN_API = "/intermediate/{}/certificate"
# GET /intermediate/{intermediate_id}/certificates
LIST_API = "/intermediate/{}/certificates"
# GET /intermediate/{intermediate_id}/certificate/{serial_number}
GET_API = "/intermediate/{}/certificate/{}"

# check input data locally with regexs
REGEX_GITHUB_TOKEN = "^[a-zA-Z0-9_]+$"
REGEX_INTERMEDIATE = "^[0-9]{2}$"
REGEX_TTL = "^[1-9][0-9]{0,4}h$"
REGEX_SERIAL = "^(?:[a-f0-9]{2}-){19}[a-f0-9]{2}$"

# network timeout
HTTP_CLIENT_TIMEOUT = 20  # max in seconds

# ugly return codes
EXIT_FAILURE = 1
EXIT_SUCCESS = 0


# authentication with GitHub IDP
def github_idp_login():

    github_token = getpass.getpass("GitHub personal access: ")
    if not re.compile(REGEX_GITHUB_TOKEN).match(github_token):
        print("Unexpected format of GitHub personal token.", file=sys.stderr)
        raise KeyError

    login_endpoint = "{}{}{}".format(SERVER_ADDRESS, API_VERSION, LOGIN_API)
    try:
        res = requests.post(login_endpoint, json={
                            "token": github_token},
                            timeout=HTTP_CLIENT_TIMEOUT)
        token = res.json()["token"]
    except requests.exceptions.RequestException:
        print("Timeout or network errors.", file=sys.stderr)
        raise
    except ValueError:
        print("Could not unmarshal JSON in /login response.", file=sys.stderr)
        raise
    except KeyError:
        print("Invalid credentials.", file=sys.stderr)
        raise

    return token


def client_list(args):

    # parameters
    intermediate = vars(args)["intermediate"]

    if not re.match(REGEX_INTERMEDIATE, intermediate):
        print("Unexpected Intermediate ID format. Please retry.",
              file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    try:
        # get a client token now using GitHub IDP
        token = github_idp_login()
    except Exception:
        sys.exit(EXIT_FAILURE)

    list_endpoint = (
        f"{SERVER_ADDRESS}{API_VERSION}"
        f"{LIST_API.format(intermediate)}"
    )
    try:
        req = requests.get(
            list_endpoint,
            headers={"Authorization": "Bearer {}".format(token)},
            timeout=HTTP_CLIENT_TIMEOUT
        )
        list_api_response = req.json()
        print(json.dumps(list_api_response, indent=4, sort_keys=True))
    except ValueError:
        print("Unexpected JSON response.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except requests.exceptions.RequestException:
        print(
            "Network error during the request. Please try again shortly.",
            file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except KeyError:
        print("Authorization error.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    sys.exit(EXIT_SUCCESS)


def client_get(args):

    # parameters
    intermediate = vars(args)["intermediate"]
    serial = vars(args)["serial"]

    if not re.match(REGEX_INTERMEDIATE, intermediate):
        print("Unexpected Intermediate ID format. Please retry.",
              file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    if not re.match(REGEX_SERIAL, serial):
        print("Serial doesn't match expected format.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    try:
        # get a client token now using GitHub IDP
        token = github_idp_login()
    except Exception:
        sys.exit(EXIT_FAILURE)

    get_endpoint = (
        f"{SERVER_ADDRESS}{API_VERSION}"
        f"{GET_API.format(intermediate, serial)}"
    )
    try:
        req = requests.get(
            get_endpoint,
            headers={"Authorization": "Bearer {}".format(token)},
            timeout=HTTP_CLIENT_TIMEOUT
        )
        get_api_response = req.json()
        print(json.dumps(get_api_response, indent=4, sort_keys=True))
    except ValueError:
        print("Unexpected JSON response.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except requests.exceptions.RequestException:
        print(
            "Network error during the request. Please try again shortly.",
            file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except KeyError:
        print("Authorization error.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    sys.exit(EXIT_SUCCESS)


def client_sign(args):

    # parameters
    csr = vars(args)["pem-csr-file"].read()
    ttl = vars(args)["ttl"]
    intermediate = vars(args)["intermediate"]
    email_flag = vars(args)["send_email"]
    no_confirm_flag = vars(args)["no_confirm"]

    if not re.match(REGEX_INTERMEDIATE, intermediate):
        print("Unexpected Intermediate ID format. Please retry.",
              file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    # optional argument
    if ttl is not None and not re.match(REGEX_TTL, ttl):
        print("Unexpected ttl format. Please retry.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    # check the CSR body and parse the email address
    try:
        csr_obj = load_pem_x509_csr(
            bytes(csr, encoding="utf-8"), crypto_backend())
        csr_subj_emails = [e.value for e in
                           csr_obj.subject.get_attributes_for_oid(
                               X509NameOID.EMAIL_ADDRESS
                           )]
    except ValueError:
        print("The CSR is not in PEM format.", file=sys.stderr)
        return
    except IndexError:
        csr_subj_emails = None

    # ask for confirmation unless force flag
    if not no_confirm_flag:
        if not email_flag:
            choice = input(
                "No email message will be sent. Confirm with \"y\": ")
            if choice != "y":
                print("bye!")
                sys.exit(EXIT_SUCCESS)
        else:
            choice = input((
                "An email will be sent to {}, "
                "in addition to the Intermediate default \"cc\" address."
                "Confirm with \"y\": "
            ).format(csr_subj_emails))
            if choice != "y":
                print("bye!")
                sys.exit(EXIT_SUCCESS)

    try:
        # get a client token now using GitHub IDP
        token = github_idp_login()
    except Exception:
        sys.exit(EXIT_FAILURE)

    # build req body
    req_payload = {"csr": csr}
    if ttl is not None:
        req_payload["ttl"] = ttl
    if email_flag is not None:
        req_payload["email_flag"] = email_flag

    csr_sign_endpoint = (
        f"{SERVER_ADDRESS}{API_VERSION}"
        f"{SIGN_API.format(intermediate)}"
    )
    try:
        req = requests.post(
            csr_sign_endpoint,
            json=req_payload,
            headers={"Authorization": "Bearer {}".format(token)},
            timeout=HTTP_CLIENT_TIMEOUT
        )
        sign_api_response = req.json()
        certificate = sign_api_response["certificate"]
    except ValueError:
        print("Unexpected JSON response.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except requests.exceptions.RequestException:
        print(
            "Network error during the request. Please try again shortly.",
            file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except KeyError:
        print("Authorization error.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    csr_filename = vars(args)["pem-csr-file"].name
    certificate_filename = "{}.certificate.pem".format(csr_filename)
    with open(certificate_filename, "w") as f:
        f.write(certificate)

    print("Certificate written to {}".format(certificate_filename))
    sys.exit(EXIT_SUCCESS)


def client_revoke(args):

    # parameters
    intermediate = vars(args)["intermediate"]
    serial = vars(args)["serial"]
    email_flag = vars(args)["send_email"]
    no_confirm_flag = vars(args)["no_confirm"]

    if not re.match(REGEX_INTERMEDIATE, intermediate):
        print("Unexpected Intermediate ID format. Please retry.",
              file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    if not re.match(REGEX_SERIAL, serial):
        print("Serial doesn't match expected format.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    # ask for confirmation
    if not no_confirm_flag:
        if not email_flag:
            choice = input(
                (
                    "An email will not be sent to the email subject."
                    "Confirm with \"y\": "
                )
            )
            if choice != "y":
                print("bye!")
                sys.exit(EXIT_SUCCESS)

    try:
        # get a client token now
        token = github_idp_login()
    except Exception:
        sys.exit(EXIT_FAILURE)

    # build req body
    req_payload = {}
    if email_flag is not None:
        req_payload["email_flag"] = email_flag

    revoke_endpoint = (
        f"{SERVER_ADDRESS}{API_VERSION}"
        f"{GET_API.format(intermediate, serial)}"
    )
    try:
        req = requests.delete(
            revoke_endpoint,
            json=req_payload,
            headers={"Authorization": "Bearer {}".format(token)},
            timeout=HTTP_CLIENT_TIMEOUT
        )
        revoke_api_response = req.json()
        _ = revoke_api_response["revocation_time"]  # do nothing
        print(revoke_api_response)
    except ValueError:
        print("Unexpected JSON response.", file=sys.stderr)
    except requests.exceptions.RequestException:
        print(
            "Network error during the request. Please try again shortly.",
            file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    except KeyError:
        print("Authorization error.", file=sys.stderr)
        sys.exit(EXIT_FAILURE)

    print("Certificate revoked")
    sys.exit(EXIT_SUCCESS)


def main():

    argparser = argparse.ArgumentParser()
    subparser = argparser.add_subparsers(dest="command")
    subparser.required = True

    list_parser = subparser.add_parser("list")
    list_parser.add_argument("intermediate")
    list_parser.set_defaults(call=client_list)

    get_parser = subparser.add_parser("get")
    get_parser.add_argument("intermediate")
    get_parser.add_argument("serial")
    get_parser.set_defaults(call=client_get)

    sign_parser = subparser.add_parser("sign")
    sign_parser.add_argument("intermediate")
    sign_parser.add_argument("pem-csr-file", type=argparse.FileType('r'))
    sign_parser.add_argument("--ttl", metavar="ttl")
    sign_parser.add_argument("--send-email", action="store_true")
    sign_parser.add_argument("--no-confirm", action="store_true")
    sign_parser.set_defaults(call=client_sign)

    revoke_parser = subparser.add_parser("revoke")
    revoke_parser.add_argument("intermediate")
    revoke_parser.add_argument("serial")
    revoke_parser.add_argument("--send-email", action="store_true")
    revoke_parser.add_argument("--no-confirm", action="store_true")
    revoke_parser.set_defaults(call=client_revoke)

    args = argparser.parse_args()
    args.call(args)
    return


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n... bye!", file=sys.stderr)
