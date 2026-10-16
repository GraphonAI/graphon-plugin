# Express

## Sign an upload URL

```ts
import express from 'express';
import { randomUUID } from 'node:crypto';
import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { BUCKET, graphon } from './graphon';

export const router = express.Router();

router.post('/uploads', requireUser, async (req, res) => {
  const key = `users/${req.user.id}/uploads/${randomUUID()}`;
  const url = await getSignedUrl(
    graphon,
    new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: req.body.contentType }),
    { expiresIn: 600 }
  );
  res.json({ url, key });
});

router.get('/files/:id', requireUser, async (req, res) => {
  const record = await files.findOwned(req.params.id, req.user.id);
  if (!record) {
    return res.sendStatus(404);
  }
  const url = await getSignedUrl(
    graphon,
    new GetObjectCommand({ Bucket: BUCKET, Key: record.key }),
    { expiresIn: 300 }
  );
  res.redirect(url);
});
```

Check ownership before you sign. A signed URL carries no identity of its own:
anyone holding it can read the object until it expires.

## Do not proxy the bytes

Avoid `multer` and a server-side re-upload for user files. It doubles the
transfer, holds the file in memory, and gives no benefit over a presigned
`PUT`.
