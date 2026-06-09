import json
import boto3
import os
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
sites_table = dynamodb.Table(os.environ["SITES_TABLE"])
backups_table = dynamodb.Table(os.environ["BACKUPS_TABLE"])


def respond(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }


def get_user(event):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    return claims.get("sub"), claims.get("cognito:groups", "").split(",")


def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/")
    user_id, groups = get_user(event)

    # ── GET /sites ─────────────────────────────────────────────────────────────
    if method == "GET" and path == "/sites":
        if "Admin" in groups:
            result = sites_table.scan()
        else:
            result = sites_table.query(
                IndexName="OwnerIndex",
                KeyConditionExpression=boto3.dynamodb.conditions.Key("ownerId").eq(user_id),
            )
        return respond(200, result.get("Items", []))

    # ── POST /sites ────────────────────────────────────────────────────────────
    if method == "POST" and path == "/sites":
        body = json.loads(event.get("body") or "{}")
        site_id = str(uuid.uuid4())
        item = {
            "siteId": site_id,
            "ownerId": user_id,
            "name": body.get("name", ""),
            "domain": body.get("domain", ""),
            "status": "pending",
            "createdAt": datetime.now(timezone.utc).isoformat(),
        }
        sites_table.put_item(Item=item)
        return respond(201, item)

    # ── GET /sites/{siteId} ────────────────────────────────────────────────────
    if method == "GET" and path.startswith("/sites/"):
        site_id = path.split("/")[2]
        result = sites_table.get_item(Key={"siteId": site_id})
        item = result.get("Item")
        if not item:
            return respond(404, {"error": "not found"})
        if "Admin" not in groups and item.get("ownerId") != user_id:
            return respond(403, {"error": "forbidden"})
        return respond(200, item)

    # ── GET /backups?siteId=xxx ────────────────────────────────────────────────
    if method == "GET" and path == "/backups":
        site_id = event.get("queryStringParameters", {}).get("siteId")
        if not site_id:
            return respond(400, {"error": "siteId required"})
        result = backups_table.query(
            IndexName="SiteBackupsIndex",
            KeyConditionExpression=boto3.dynamodb.conditions.Key("siteId").eq(site_id),
        )
        return respond(200, result.get("Items", []))

    return respond(404, {"error": "route not found"})
