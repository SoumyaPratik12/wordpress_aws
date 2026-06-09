"""
Step Functions tasks — each Lambda handles one state in the deploy workflow.
The state machine passes the full event payload between steps.
"""
import json
import boto3
import os
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
sites_table = dynamodb.Table(os.environ.get("SITES_TABLE", "Sites"))


def _update_site_status(site_id: str, status: str, extra: dict = None):
    expr = "SET #s = :s, updatedAt = :t"
    names = {"#s": "status"}
    values = {":s": status, ":t": datetime.now(timezone.utc).isoformat()}
    if extra:
        for k, v in extra.items():
            expr += f", #{k} = :{k}"
            names[f"#{k}"] = k
            values[f":{k}"] = v
    sites_table.update_item(
        Key={"siteId": site_id},
        UpdateExpression=expr,
        ExpressionAttributeNames=names,
        ExpressionAttributeValues=values,
    )


def provision_infrastructure(event, context):
    """State 1 — mark site as provisioning, return infra details."""
    site_id = event["siteId"]
    _update_site_status(site_id, "provisioning")
    return {**event, "infraReady": True, "instanceType": "t3.micro"}


def install_wordpress(event, context):
    """State 2 — simulate WP install (replace with real SSM/EC2 calls)."""
    site_id = event["siteId"]
    _update_site_status(site_id, "installing")
    wp_admin_url = f"https://{event.get('domain', site_id)}/wp-admin"
    return {**event, "wpAdminUrl": wp_admin_url, "wpInstalled": True}


def configure_dns(event, context):
    """State 3 — simulate DNS configuration."""
    site_id = event["siteId"]
    _update_site_status(site_id, "configuring_dns")
    return {**event, "dnsConfigured": True}


def run_health_check(event, context):
    """State 4 — verify the site is reachable."""
    site_id = event["siteId"]
    # Real implementation: HTTP GET the site URL and check 200
    healthy = True
    if healthy:
        _update_site_status(site_id, "active", {"wpAdminUrl": event.get("wpAdminUrl", "")})
        return {**event, "healthy": True}
    raise RuntimeError(f"Health check failed for site {site_id}")


def notify_complete(event, context):
    """State 5 — send completion notification (SNS/SES wired in step 7)."""
    site_id = event["siteId"]
    return {**event, "deployComplete": True, "completedAt": datetime.now(timezone.utc).isoformat()}
