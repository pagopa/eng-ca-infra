import datetime
import email.mime.application
import email.mime.multipart
import email.mime.text
import json
import logging
import os
import smtplib
import string

import boto3
import botocore.config
import botocore.exceptions
import urllib3

HTTP_TIMEOUT = 3  # in seconds
http = urllib3.PoolManager(timeout=HTTP_TIMEOUT)
BOTO3_CONFIG_TIMEOUT = botocore.client.Config(
    connect_timeout=HTTP_TIMEOUT,
    read_timeout=HTTP_TIMEOUT
)
EMAIL_STATUS_SUCCESS = "ESS"
EMAIL_STATUS_FAILURE = "ESF"
EMAIL_STATUS_NO_RECIPIENTS = "ESNR"
EMAIL_STATUS_UNREQUESTED = "ESU"

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

def send_email(subject, recipients, html_body, attachments):
    logger.info("send_email")
    if os.getenv("ENV") == "PROD":
        # create a multipart message
        msg = email.mime.multipart.MIMEMultipart()
        sender = os.getenv("SMTP_USERNAME")
        # RFC 5322
        msg["To"] = recipients
        msg["Cc"] = "security+ca@pagopa.it"
        msg["From"] = sender
        msg["Subject"] = subject
        # attach html "part"
        msg.attach(email.mime.text.MIMEText(html_body, "html"))
        # convention is that attachment is a tuple -> (filename, PEM-encoded)
        # attach "attachments" part
        for attachment in attachments:
            part = email.mime.application.MIMEApplication(
                attachment[1], "pkix-cert")
            part.add_header("Content-Disposition",
                            "attachment; filename={}".format(attachment[0]))
            msg.attach(part)
        # send email
        server = smtplib.SMTP(
            host=os.getenv("SMTP_HOST"),
            port=os.getenv("SMTP_PORT"),
            timeout=HTTP_TIMEOUT)
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(sender, os.getenv("SMTP_PASSWORD"))
        # RFC5321 MAIL FROM; RCPT TO
        # injected headers here will trigger an exception
        server.sendmail(
            sender,
            msg["To"].split(", ") + msg["Cc"].split(", "),
            msg.as_string()
        )
        logger.info("email sent")
        server.close()


def send_slack(msg_body):
    logger.info("send slack")
    # if os.getenv("ENV") == "PROD":
    msg = {
        "channel": os.getenv("SLACK_CHANNEL"),
        "username": os.getenv("SLACK_USERNAME"),
        "text": msg_body
    }
    http.request('POST', os.getenv("SLACK_WEBHOOK"), body=json.dumps(msg))
    logger.info("slack message sent")


def add_email_delivery_status_to_msg(msg_body, email_delivery_status):
    logger.info("add email delivery status")
    if email_delivery_status == EMAIL_STATUS_SUCCESS:
        msg_body = "\n".join(
            (msg_body, "Successful email notification delivery."))
        logger.info("email status SUCCESS added")
    elif email_delivery_status == EMAIL_STATUS_FAILURE:
        msg_body = "\n".join((msg_body, "Failed email notification delivery."))
        logger.info("email status FAILURE added")
    elif email_delivery_status == EMAIL_STATUS_UNREQUESTED:
        msg_body = "\n".join(
            (msg_body, "An email notification was not requested by the operator."))
        logger.info("email status UNREQUESTED added")
    elif email_delivery_status == EMAIL_STATUS_NO_RECIPIENTS:
        msg_body = "\n".join(
            (msg_body,
             "An email notification was requested, but the certificate had an empty email field."))
        logger.info("email status NO RECIPIENTS added")
    return msg_body


def notify_login_slack(data):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_login_template.txt"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("login template found")
        slack_login_template = string.Template(tmpl_f.read())
    # USR: GitHub username
    # IPA: IP Address
    # HTK: session token for tracking requests
    msg_body = slack_login_template.substitute({
        "USR": data["USR"],
        "IPA": data["IPA"],
        "HTK": data["HTK"]
    })
    # send to Slack
    send_slack(msg_body)


def notify_read_slack(data):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_read_template.txt"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("read template found")
        slack_read_template = string.Template(tmpl_f.read())
    # USR: GitHub username
    # IPA: IP Address
    # HTK: session token for tracking requests
    msg_body = slack_read_template.substitute({
        "IPA": data["IPA"],
        "RAP": data["RAP"],
        "HTK": data["HTK"]
    })
    # send to Slack
    send_slack(msg_body)


def notify_list_slack(data):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_list_template.txt"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("list template found")
        slack_list_template = string.Template(tmpl_f.read())
    # USR: GitHub username
    # IPA: IP Address
    # HTK: session token for tracking requests
    msg_body = slack_list_template.substitute({
        "IPA": data["IPA"],
        "RAP": data["RAP"],
        "HTK": data["HTK"]
    })
    # send to Slack
    send_slack(msg_body)


def notify_signature_slack(data, email_delivery):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_sign_template.txt"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("sign template found")
        slack_sign_template = string.Template(tmpl_f.read())
    # IPA: IP address
    # RAP: request API
    # SUB: certificate subject field
    # EKU: certificate extended key usage field
    # SAN: certificate SAN field
    # NVB: certificate not valid before field
    # NVA: certificate not valid after field
    # SER: certificate serial number
    # HTK: session token for tracking requests
    msg_body = slack_sign_template.substitute({
        "IPA": data["IPA"],
        "RAP": data["RAP"],
        "HTK": data["HTK"],
        "SUB": data["certificate"]["SUB"],
        "EKU": data["certificate"]["EKU"],
        "SAN": data["certificate"]["SAN"],
        "NVB": data["certificate"]["NVB"],
        "NVA": data["certificate"]["NVA"],
        "SER": data["certificate"]["SER"]
    })
    msg_body = add_email_delivery_status_to_msg(msg_body, email_delivery)
    send_slack(msg_body)


def notify_revocation_slack(data, email_delivery):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_revocation_template.txt"]),
              "r", encoding="utf-8") as tmpl_f:
        logger.info("revoke template found")
        slack_revocation_template = string.Template(tmpl_f.read())
    # IPA: IP Address
    # RAP: request API
    # SER: certificate serial number
    # HTK: session token for tracking requests
    msg_body = slack_revocation_template.substitute({
        "IPA": data["IPA"],
        "RAP": data["RAP"],
        "SER": data["certificate"]["SER"],
        "HTK": data["HTK"]
    })
    msg_body = add_email_delivery_status_to_msg(msg_body, email_delivery)
    send_slack(msg_body)


def notify_reminder_slack(data, email_delivery):
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/slack_reminder_template.txt"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("reminder template found")
        slack_reminder_template = string.Template(tmpl_f.read())
    # NVA: certificate not valid after field
    # INT: certificate intermediate identifier
    # SER: certificate serial number
    msg_body = slack_reminder_template.substitute({
        "INT": data["certificate"]["INT"],
        "NVA": data["certificate"]["NVA"],
        "SER": data["certificate"]["SER"]
    })
    msg_body = add_email_delivery_status_to_msg(msg_body, email_delivery)
    send_slack(msg_body)


def notify_signature_email(data):
    # bail out early if email not required
    # SEF: send email flag
    send_email_flag = data["SEF"]
    if send_email_flag is False:
        return EMAIL_STATUS_UNREQUESTED
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/email_sign_template.html"]), "r", encoding="utf-8") as tmpl_f:
        logger.info("email - sign template found")
        email_sign_template = string.Template(tmpl_f.read())
    # TEA: To email addresses, in certificate data
    recipients = data["certificate"]["TEA"]
    # bail-out early in case of None
    if recipients is None:
        return EMAIL_STATUS_FAILURE
    # EKU: certificate extended key usage field
    # INT: certificate intermediate identifier
    # SUB: certificate subject field
    # SAN: certificate SAN field
    # NVB: certificate not valid before field
    # NVA: certificate not valid after field
    # SER: certificate serial number
    # HTK: session token for tracking requests
    html_body = email_sign_template.substitute({
        "EKU": data["certificate"]["EKU"],
        "INT": data["certificate"]["INT"],
        "SUB": data["certificate"]["SUB"],
        "SAN": data["certificate"]["SAN"],
        "NVB": data["certificate"]["NVB"],
        "NVA": data["certificate"]["NVA"],
        "SER": data["certificate"]["SER"],
        "HTK": data["HTK"]
    })
    attachments = data["attachments"]
    subject = "A new certificate has been signed - PagoPA CA"
    send_email(subject, recipients, html_body, attachments)
    return EMAIL_STATUS_SUCCESS


def notify_revocation_email(data):
    # bail out early if email not required
    # SEF: send email flag
    send_email_flag = data["SEF"]
    if send_email_flag is False:
        return EMAIL_STATUS_UNREQUESTED
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/email_revocation_template.html"]),
              "r", encoding="utf-8") as tmpl_f:
        logger.info("email - revoke template found")
        email_sign_template = string.Template(tmpl_f.read())
    # TEA: To email address, in certificate data
    recipients = data["certificate"]["TEA"]
    # bail-out early in case of None
    if recipients is None:
        return EMAIL_STATUS_FAILURE
    # EKU: certificate extended key usage field
    # INT: certificate intermediate identifier
    # SUB: certificate subject field
    # SAN: certificate SAN field
    # NVB: certificate not valid before field
    # RAT: revoked at field
    # SER: certificate serial number
    # HTK: session token for tracking requests
    html_body = email_sign_template.substitute({
        "EKU": data["certificate"]["EKU"],
        "INT": data["certificate"]["INT"],
        "SUB": data["certificate"]["SUB"],
        "SAN": data["certificate"]["SAN"],
        "NVB": data["certificate"]["NVB"],
        "RAT": data["certificate"]["RAT"],
        "SER": data["certificate"]["SER"],
        "HTK": data["HTK"]
    })
    # send an empty list as attachments
    attachments = []
    subject = "A certificate has been revoked - PagoPA CA"
    send_email(subject, recipients, html_body, attachments)
    return EMAIL_STATUS_SUCCESS


def notify_reminder_email(data):
    # bail out early if email not required
    # SEF: send email flag
    send_email_flag = data["SEF"]
    if send_email_flag is False:
        return EMAIL_STATUS_UNREQUESTED
    # open the template
    with open("".join([os.getenv("LAMBDA_TASK_ROOT"),
                       "/templates/email_reminder_template.html"]),
              "r", encoding="utf-8") as tmpl_f:
        logger.info("email - notify template found")
        email_reminder_template = string.Template(tmpl_f.read())
    # TEA: To email addresses, in certificate data
    recipients = data["certificate"]["TEA"]
    # bail-out early in case of None
    if recipients is None:
        return EMAIL_STATUS_NO_RECIPIENTS
    # EKU: certificate extended key usage field
    # INT: certificate intermediate identifier
    # SUB: certificate subject field
    # SAN: certificate SAN field
    # NVB: certificate not valid before field
    # NVA: certificate not valid after field
    # SER: certificate serial number
    html_body = email_reminder_template.substitute({
        "EKU": data["certificate"]["EKU"],
        "INT": data["certificate"]["INT"],
        "SUB": data["certificate"]["SUB"],
        "SAN": data["certificate"]["SAN"],
        "NVB": data["certificate"]["NVB"],
        "NVA": data["certificate"]["NVA"],
        "SER": data["certificate"]["SER"],
    })
    # send an empty list as attachments
    attachments = []
    subject = "A certificate is expiring - PagoPA CA"
    send_email(subject, recipients, html_body, attachments)
    return EMAIL_STATUS_SUCCESS


def save_certificate_info(data):
    # SER: certificate serial number (hash key)
    # INT: certificate intermediate identifier (secondary index, hash key)
    # NVA: certificate not valid after field (secondary index, sort key)

    logger.info("save certificate info")
    table = dynamodb.Table(os.getenv("AWS_DYNAMODB_TABLE"))
    timestamp = int(datetime.datetime.fromisoformat(
        data["certificate"]["NVA"]).timestamp())
    table.put_item(
        Item={
            "SER": data["certificate"]["SER"],
            "INT": data["certificate"]["INT"],
            "NVA": timestamp,
            "OTHER": {
                "EKU": data["certificate"]["EKU"],
                "SUB": data["certificate"]["SUB"],
                "SAN": data["certificate"]["SAN"],
                "NVB": data["certificate"]["NVB"],
                "TEA": data["certificate"]["TEA"],
                "SEF": data["SEF"]
            }
        },
        ConditionExpression="attribute_not_exists(SER)"
    )
    logger.info("certificate info saved")


def delete_certificate_info(data):

    logger.info("delete certificate")
    table = dynamodb.Table(os.getenv("AWS_DYNAMODB_TABLE"))
    # SER: certificate serial number, it's the hash key
    table.delete_item(
        Key={
            "SER": data["certificate"]["SER"]
        },
        ConditionExpression="attribute_exists(SER)"
    )
    logger.info("certificate deleted")


def handler(event, _context):
    message = json.loads(event['Records'][0]['Sns']
                         ['Message'])  # this is a fixed format
    message_event = message["event"]
    message_data = message["data"]
    # understand what to do based on the "message_event" type
    # on login, notify Slack
    if message_event == "LOGIN":
        logger.info("LOGIN event received")
        notify_login_slack(message_data)
    # on read, notify Slack
    elif message_event == "READ":
        logger.info("READ event received")
        notify_read_slack(message_data)
    # on list, notify Slack
    elif message_event == "LIST":
        logger.info("LIST event received")
        notify_list_slack(message_data)
    # on signature, notify via email and Slack (also report email delivery status)
    elif message_event == "SIGNATURE":
        logger.info("SIGNATURE event received")
        # save to DynamoDB
        try:
            save_certificate_info(message_data)
        except botocore.exceptions.ClientError as ex:
            if ex.response['Error']['Code'] == 'ConditionalCheckFailedException':
                # this a duplicated execution of our lambda, bail out
                logger.info("Duplicated lambda execution")
                return
            # in case we failed for other reasons, just log
            else:
                logger.warning(
                    "".join(("SIGNATURE event: failed to save to DynamoDB because of ", repr(ex))))
        # now attempt to send an email
        try:
            email_delivery_status = notify_signature_email(message_data)
        except Exception as ex:
            logger.warning(
                "".join(("SIGNATURE event: failed to deliver email because of ", repr(ex))))
            email_delivery_status = EMAIL_STATUS_FAILURE
        # notify Slack channel
        notify_signature_slack(message_data, email_delivery_status)
    # on revocation, notify via email and Slack (also report email delivery status)
    elif message_event == "REVOCATION":
        logger.info("REVOCATION event received")
        # cert is revoked, so delete from the DynamoDB table that stores the certificate data
        # if we fail here, we just log
        try:
            delete_certificate_info(message_data)
        except botocore.exceptions.ClientError as ex:
            if ex.response['Error']['Code'] == 'ConditionalCheckFailedException':
                # this a duplicated execution of our lambda, bail out
                logger.info("Duplicated lambda execution")
                return
            # in case we failed for other reasons, just log
            else:
                logger.warning("".join(
                    ("REVOCATION event: failed to delete from DynamoDB because of ", repr(ex))))
        # now attempt to send an email
        try:
            email_delivery_status = notify_revocation_email(message_data)
        except Exception as ex:
            logger.warning(
                "".join(("REVOCATION event: failed to deliver email because of ", repr(ex))))
            email_delivery_status = EMAIL_STATUS_FAILURE
        # notify Slack channel
        notify_revocation_slack(message_data, email_delivery_status)
    # on reminder, notify via email and Slack (also report email delivery status)
    elif message_event == "REMINDER":
        logger.info("REMINDER event received")
        # we are willing to tolerate duplicate reminders here
        try:
            email_delivery_status = notify_reminder_email(message_data)
        except Exception as ex:
            logger.warning(
                "".join(("REMINDER event: failed to deliver email because of ", repr(ex))))
            email_delivery_status = EMAIL_STATUS_FAILURE
        # on successful email delivery or unrequested...
        if email_delivery_status != EMAIL_STATUS_FAILURE:
            # delete from the reminder DynamoDB table
            try:
                delete_certificate_info(message_data)
            except botocore.exceptions.ClientError as ex:
                if ex.response['Error']['Code'] == 'ConditionalCheckFailedException':
                    # this a duplicated execution of our lambda, bail out
                    logger.info("Duplicated lambda execution")
                    return
                    # in case we failed for other reasons, just log
                else:
                    logger.warning("".join(
                        ("event: REMINDER, failed to delete from DynamoDB because of ", repr(ex))))
        # notify Slack channel
        notify_reminder_slack(message_data, email_delivery_status)
