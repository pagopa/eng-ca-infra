"""Lambda triggered once per day to update the Vault's CRL"""
import json

import requests
from utils.config import Config
from utils.logger import logger
from utils.utils import get_vault_address

VAULT_ADDRESS = get_vault_address()
VAULT_API_PREFIX = "/v1"
VAULT_INTERNAL_LOGIN = Config.get_env("VAULT_INTERNAL_LOGIN_PATH")
VAULT_LIST_MOUNTS = Config.get_env("VAULT_LIST_MOUNTS")
# skip inital / char
VAULT_ROTATE_CRL = Config.get_env("VAULT_ROTATE_CRL")
VAULT_TIDY = Config.get_env("VAULT_TIDY")
TMP_PATH = Config.get_env("VAULT_TMP_PATH")
CACERT = Config.get_env("VAULT_CA_CERT")
USERNAME = Config.get_env("VAULT_CRL_USERNAME")
PASSWORD = Config.get_env("PASSWORD")


def lambda_handler(event, context):
    "Lambda triggered hourly to update Vault's CRL"

    # retrieve a token from the internal login endpoint
    response = requests.post(
        f"{VAULT_ADDRESS}{VAULT_API_PREFIX}{VAULT_INTERNAL_LOGIN}{USERNAME}",
        data=json.dumps({"password": PASSWORD}),
        verify=CACERT,
        timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT")),
    )

    if not response:
        logger.error("Failed retrieving token from the internal login endpoint")
        return -1

    TOKEN = response.json()["auth"]["client_token"]

    if TOKEN and TOKEN != "null":
        # retrieve all mount points with a pki backend
        response = requests.get(
            f"{VAULT_ADDRESS}{VAULT_API_PREFIX}{VAULT_LIST_MOUNTS}",
            headers={"X-Vault-Token": TOKEN},
            verify=CACERT,
            timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT")),
        )
        if response.status_code != 200:
            logger.error("Failed listing mounts or talking with a standby node")
            return -1
        MOUNTS = [
            k
            for k, v in response.json().items()
            if v
            and not isinstance(v, str)
            and not isinstance(v, bool)
            and not isinstance(v, int)
            and v.get("type") == "pki"
        ]  # todo make this less ugly
        for mount in MOUNTS:
            # rotate each endpoint individually, add a / char as MOUNT come in this form: "pki/"
            logger.info(f"Rotating and tidying {mount}")
            # warn if error on some intermediate
            response = requests.get(
                f"{VAULT_ADDRESS}{VAULT_API_PREFIX}/{mount}{VAULT_ROTATE_CRL}",
                headers={"X-Vault-Token": TOKEN},
                verify=CACERT,
                timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT")),
            )
            if response.status_code != 200:
                logger.error(f"Failed rotating CRL of {mount}")
                continue  # skip tidying
            response = requests.post(
                f"{VAULT_ADDRESS}{VAULT_API_PREFIX}/{mount}{VAULT_TIDY}",
                headers={"X-Vault-Token": TOKEN, "Content-Type": "application/json"},
                data=json.dumps(
                    {
                        "tidy_cert_store": "true",
                        "tidy_revoked_certs": "true",
                        "safety_buffer": "24h",
                    }
                ),
                verify=CACERT,
                timeout=int(Config.get_defaulted_env("HTTP_CLIENT_INTERNAL_TIMEOUT")),
            )
            # for /tidy endpoint, it is Accepted, 202
            if response.status_code != 202:
                logger.error(f"Failed tidying CRL of {mount}")
                continue  # resume loop
            logger.info(f"Rotated and tidied {mount}")
        logger.info(
            "All CRLs rotated."
        )  # todo do we want to print a list of all the CRL that was not rotated?
    else:
        logger.warning("Could not retrieve a valid TOKEN.")
