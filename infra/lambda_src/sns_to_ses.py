import json
import boto3
import os

ses = boto3.client("ses", region_name="ap-south-1")
TO_EMAIL   = os.environ["ALERT_EMAIL"]
FROM_EMAIL = os.environ["ALERT_EMAIL"]


def handler(event, context):
    for record in event.get("Records", []):
        sns_msg = record.get("Sns", {})
        subject = sns_msg.get("Subject") or "[wp-platform] Alert"
        message = sns_msg.get("Message", "")

        ses.send_email(
            Source=FROM_EMAIL,
            Destination={"ToAddresses": [TO_EMAIL]},
            Message={
                "Subject": {"Data": subject[:100]},
                "Body":    {"Text": {"Data": message}},
            },
        )
    return {"status": "ok"}
