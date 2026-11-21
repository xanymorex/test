import json
import os
import uuid
from datetime import datetime, timezone
import boto3

s3 = boto3.client("s3")


def lambda_handler(event, context):
    # This is a placeholder. Replace with validated business logic.
    # Never log sensitive request bodies or processed records.
    raw_body = event.get("body") or "{}"
    try:
        payload = json.loads(raw_body)
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": json.dumps({"message": "Invalid JSON"})}

    record_id = str(uuid.uuid4())
    object_key = f"processed/{record_id}.json"

    record = {
        "record_id": record_id,
        "received_at": datetime.now(timezone.utc).isoformat(),
        "payload": payload
    }

    s3.put_object(
        Bucket=os.environ["DATA_BUCKET"],
        Key=object_key,
        Body=json.dumps(record).encode("utf-8"),
        ContentType="application/json",
        ServerSideEncryption="aws:kms"
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "record_id": record_id,
            "status": "stored"
        })
    }
