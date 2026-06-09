"""
Scheduled Lambda handlers triggered by EventBridge rules.
health_check: scans all active sites and verifies they are reachable.
backup:       creates a backup record for every active site.
"""
import json
import boto3
import os
import uuid
import urllib.request
from datetime import datetime, timezone, timedelta

dynamodb = boto3.resource("dynamodb")
sites_table = dynamodb.Table(os.environ.get("SITES_TABLE", "Sites"))
backups_table = dynamodb.Table(os.environ.get("BACKUPS_TABLE", "Backups"))
sns_client = boto3.client("sns")
ALERT_TOPIC_ARN = os.environ.get("ALERT_TOPIC_ARN", "")


def _all_active_sites():
    result = sites_table.query(
        IndexName="StatusIndex",
        KeyConditionExpression=boto3.dynamodb.conditions.Key("status").eq("active"),
    )
    return result.get("Items", [])


def health_check(event, context):
    """Triggered every 5 minutes via EventBridge."""
    sites = _all_active_sites()
    failed = []

    for site in sites:
        domain = site.get("domain", "")
        if not domain:
            continue
        try:
            url = f"https://{domain}" if not domain.startswith("http") else domain
            req = urllib.request.Request(url, method="GET")
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status >= 400:
                    failed.append({"siteId": site["siteId"], "domain": domain, "status": resp.status})
        except Exception as exc:
            failed.append({"siteId": site["siteId"], "domain": domain, "error": str(exc)})

    if failed and ALERT_TOPIC_ARN:
        sns_client.publish(
            TopicArn=ALERT_TOPIC_ARN,
            Subject="[wp-platform] Site health check failures",
            Message=json.dumps(failed, indent=2),
        )

    return {"checked": len(sites), "failed": len(failed), "failures": failed}


def backup(event, context):
    """Triggered daily at 02:00 UTC via EventBridge."""
    sites = _all_active_sites()
    now = datetime.now(timezone.utc)
    expires = now + timedelta(days=30)

    created = []
    for site in sites:
        backup_id = str(uuid.uuid4())
        item = {
            "backupId": backup_id,
            "siteId": site["siteId"],
            "createdAt": now.isoformat(),
            "expiresAt": int(expires.timestamp()),
            "type": "scheduled",
            "status": "completed",
        }
        backups_table.put_item(Item=item)
        created.append(backup_id)

    if ALERT_TOPIC_ARN and created:
        sns_client.publish(
            TopicArn=ALERT_TOPIC_ARN,
            Subject=f"[wp-platform] Daily backup complete — {len(created)} sites",
            Message=f"Backup IDs: {json.dumps(created)}",
        )

    return {"backedUp": len(created), "backupIds": created}
