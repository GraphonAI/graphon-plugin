# Express

## Search and answer routes

```ts
import express from 'express';
import { BUCKET_ID, graphon } from './graphon-search';

export const router = express.Router();

router.post('/search', requireUser, async (req, res) => {
  const body = await graphon('search', {
    bucketId: BUCKET_ID,
    query: req.body.query,
    mode: 'hybrid',
    limit: 10,
    ...(req.body.cursor ? { cursor: req.body.cursor } : {}),
  });
  // Graphon answers from the whole bucket. Keep this tenant's keys only.
  const prefix = `orgs/${req.user.orgId}/`;
  res.json({
    results: body.results.filter((result) => result.key.startsWith(prefix)),
    nextCursor: body.nextCursor,
  });
});

router.post('/ask', requireUser, async (req, res) => {
  const turns = await conversations.turns(req.body.conversationId);
  const body = await graphon('answer', {
    bucketId: BUCKET_ID,
    query: req.body.question,
    // Oldest first, at most 32 turns. Graphon stores none of them.
    history: turns.slice(-32),
  });
  await conversations.append(req.body.conversationId, [
    { role: 'user', content: req.body.question },
    { role: 'assistant', content: body.answer ?? '' },
  ]);
  res.json({ answer: body.answer, sources: body.sources, warnings: body.warnings });
});
```

## Never take the bucket from the browser

`bucketId` comes from the server's configuration or from the signed-in user's
record. A bucket id in the request body lets one user read another tenant's
files.

## Open a result

A search result holds a key and a version, not a URL. Ask the storage API for
a download URL when the user opens the result, and check that the key belongs
to that user first. A signed URL expires, so sign it per click and never store
it.
