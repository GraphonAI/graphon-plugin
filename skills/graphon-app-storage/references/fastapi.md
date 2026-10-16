# FastAPI

## The client

`graphon.py`:

```python
import os
import boto3
from botocore.config import Config

key = os.environ["GRAPHON_API_KEY"]
# From `graphon workspaces get`. It is not a secret.
WORKSPACE_ID = "<workspace id>"

graphon = boto3.client(
    "s3",
    endpoint_url="https://" + WORKSPACE_ID + ".storage.beta.graphon.sh",
    region_name="us-east-1",
    # The access key ID is between the "_" and the ".".
    aws_access_key_id=key.split("_", 1)[1].split(".")[0],
    aws_secret_access_key=key,
    config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
)

BUCKET = os.environ["GRAPHON_BUCKET"]
```

## Sign an upload URL

```python
import uuid
from fastapi import APIRouter, Depends
from .graphon import graphon, BUCKET

router = APIRouter()

@router.post("/uploads")
def create_upload(content_type: str, user=Depends(current_user)):
    key = f"users/{user.id}/uploads/{uuid.uuid4()}"
    url = graphon.generate_presigned_url(
        "put_object",
        Params={"Bucket": BUCKET, "Key": key, "ContentType": content_type},
        ExpiresIn=600,
    )
    return {"url": url, "key": key}
```

## Serve a private object

```python
@router.get("/files/{file_id}")
def read_file(file_id: str, user=Depends(current_user)):
    record = files.find_owned(file_id, user.id)
    if record is None:
        raise HTTPException(status_code=404)
    url = graphon.generate_presigned_url(
        "get_object",
        Params={"Bucket": BUCKET, "Key": record.key},
        ExpiresIn=300,
    )
    return RedirectResponse(url)
```

`signature_version="s3v4"` and the path addressing style are both required.
Without them boto3 signs a request that Graphon rejects with 403.
