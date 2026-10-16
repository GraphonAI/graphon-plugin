# Replace another storage provider

Graphon speaks S3, so most of the change is configuration, not code.

## Already on an S3 SDK

AWS S3, Cloudflare R2, Backblaze B2, MinIO, DigitalOcean Spaces, and Wasabi all
use an S3 client. Change four things and keep the rest:

| Setting | New value |
| --- | --- |
| endpoint | `https://<workspace id>.storage.beta.graphon.sh`, with the ID from `graphon workspaces get` |
| region | `us-east-1` |
| path-style addressing | on |
| credentials | the access key ID and the key, from `GRAPHON_API_KEY` in the app's secrets |

Remove any AWS-only option: `ACL`, storage classes, `x-amz-*` headers the code
sets by hand, and KMS settings. Graphon returns 501 for the operations it does
not implement; load `graphon-troubleshoot` when you hit one.

## On a provider-specific SDK

| From | Replace |
| --- | --- |
| Vercel Blob | `put`/`head`/`del` with `PutObjectCommand`, `HeadObjectCommand`, `DeleteObjectCommand`. Vercel's `url` becomes a signed `GET`, so store the key and sign per request. |
| Supabase Storage | `storage.from(bucket).upload` with a presigned `PUT`. Row-level policies become your own ownership check before you sign. |
| Firebase Storage | `ref().put()` with a presigned `PUT`. Security rules become your own check before you sign. |
| UploadThing | Its callback with your own route that signs a `PUT` and records the key. |
| Google Cloud Storage | The GCS client with an S3 client; `bucket.file(name)` becomes `Bucket` plus `Key`. |
| Local disk | `fs.writeFile` with `PutObjectCommand`, and the served path with a signed `GET`. |

## Order of work

1. Add the Graphon client next to the old one. Do not delete the old one yet.
2. Write new objects to both, or write to Graphon and read from either, so a
   rollback stays possible.
3. Copy the existing data. Load `graphon-migrate`.
4. Check counts and checksums.
5. Switch reads to Graphon.
6. Leave the source in place until the user says to remove it.

Never delete the source in the same change that switches reads.
