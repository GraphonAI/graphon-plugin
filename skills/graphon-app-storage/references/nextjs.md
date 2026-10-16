# Next.js

App Router. The browser uploads straight to storage with a presigned `PUT`.

## 1. The client

`lib/graphon.ts`, as shown in the skill. Keep it server-only: do not import it
from a `'use client'` file.

## 2. Sign an upload URL

`app/api/uploads/route.ts`:

```ts
import { PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'node:crypto';
import { BUCKET, graphon } from '@/lib/graphon';
import { auth } from '@/lib/auth';

export async function POST(request: Request) {
  const session = await auth();
  if (!session) {
    return Response.json({ error: 'unauthorized' }, { status: 401 });
  }
  const { contentType } = (await request.json()) as { contentType: string };
  // The key comes from the session and a new id, never from the filename.
  const key = `users/${session.userId}/uploads/${randomUUID()}`;
  const url = await getSignedUrl(
    graphon,
    new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType }),
    { expiresIn: 600 }
  );
  return Response.json({ url, key });
}
```

## 3. Upload from the browser

```ts
async function upload(file: File) {
  const start = await fetch('/api/uploads', {
    method: 'POST',
    body: JSON.stringify({ contentType: file.type }),
  });
  const { url, key } = await start.json();
  await fetch(url, { method: 'PUT', body: file, headers: { 'content-type': file.type } });
  // Save the key on your own record. Do not save the signed URL.
  await fetch('/api/profile/avatar', { method: 'POST', body: JSON.stringify({ key }) });
}
```

## 4. Serve a private object

```ts
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

export async function avatarUrl(key: string) {
  return getSignedUrl(graphon, new GetObjectCommand({ Bucket: BUCKET, Key: key }), {
    expiresIn: 300,
  });
}
```

Sign the URL in a server component or a route handler, per request. Do not
cache it past its expiry, and do not put it in a static page.

## Test

```ts
it('stores an avatar', async () => {
  const key = await uploadFixture('avatar.png');
  const object = await graphon.send(new GetObjectCommand({ Bucket: BUCKET, Key: key }));
  expect(object.ContentLength).toBeGreaterThan(0);
});
```
