# TanStack Start

Sign the URL in a server function. The client never sees the key.

## Server function

```ts
import { createServerFn } from '@tanstack/react-start';
import { PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'node:crypto';

export const createUploadUrl = createServerFn({ method: 'POST' })
  .validator((input: { contentType: string }) => input)
  .handler(async ({ data }) => {
    // Import inside the handler so the client bundle never pulls in the SDK.
    const { graphon, BUCKET } = await import('./server/graphon');
    const userId = await sessionUserId();
    const key = `users/${userId}/uploads/${randomUUID()}`;
    const url = await getSignedUrl(
      graphon,
      new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: data.contentType }),
      { expiresIn: 600 }
    );
    return { url, key };
  });
```

## Client

```ts
const { url, key } = await createUploadUrl({ data: { contentType: file.type } });
await fetch(url, { method: 'PUT', body: file, headers: { 'content-type': file.type } });
```

Import the S3 client with a dynamic `import()` inside the handler. A top-level
import pulls the SDK, and the key that reads it, into the client bundle.
