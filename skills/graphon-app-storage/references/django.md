# Django

Use `django-storages` with its S3 backend. Graphon needs four settings that
differ from AWS. The key and the bucket name come from the environment. Only
the key is a secret.

## settings.py

```python
import os

key = os.environ["GRAPHON_API_KEY"]
# From `graphon workspaces get`. It is not a secret.
GRAPHON_WORKSPACE_ID = "<workspace id>"

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": os.environ["GRAPHON_BUCKET"],
            "endpoint_url": "https://" + GRAPHON_WORKSPACE_ID + ".storage.beta.graphon.sh",
            "region_name": "us-east-1",
            "addressing_style": "path",
            "signature_version": "s3v4",
            # The access key ID is between the "_" and the ".".
            "access_key": key.split("_", 1)[1].split(".")[0],
            "secret_key": key,
            # Private by default. Sign a URL per request instead.
            "default_acl": None,
            "querystring_auth": True,
            "querystring_expire": 300,
        },
    },
}
```

## Use it

```python
class Document(models.Model):
    file = models.FileField(upload_to="documents/")
```

`document.file.url` now returns a signed URL that expires in 300 seconds.

Leave `default_acl` as `None`. Setting it to `public-read` makes every upload
world-readable, and Graphon buckets are private unless the user asked for a
public bucket.

For a large user upload, sign a `PUT` URL and let the browser upload straight
to storage rather than passing the file through Django.
