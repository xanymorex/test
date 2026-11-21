import json
import os
import urllib.request
import urllib.error
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import Credentials
from botocore.session import Session


def lambda_handler(event, context):
    # Do not log the request body: it may contain sensitive information.
    body = event.get("body") or "{}"
    private_url = os.environ["PRIVATE_API_URL"]

    session = Session()
    credentials = session.get_credentials().get_frozen_credentials()
    request = AWSRequest(
        method="POST",
        url=private_url,
        data=body,
        headers={"Content-Type": "application/json"}
    )
    SigV4Auth(credentials, "execute-api", os.environ.get("AWS_REGION", "us-east-1")).add_auth(request)
    prepared = request.prepare()

    req = urllib.request.Request(
        private_url,
        data=body.encode("utf-8"),
        headers=dict(prepared.headers),
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            result = response.read().decode("utf-8")
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Request processed",
                "processing_result": json.loads(result) if result else None
            })
        }
    except urllib.error.HTTPError as exc:
        return {"statusCode": 502, "body": json.dumps({"message": "Private processing failed", "status": exc.code})}
    except Exception:
        return {"statusCode": 502, "body": json.dumps({"message": "Private processing unavailable"})}
