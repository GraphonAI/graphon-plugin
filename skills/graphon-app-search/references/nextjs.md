# Next.js

## A search route

```ts
// app/api/search/route.ts
import { NextResponse } from 'next/server';
import { BUCKET_ID, graphon } from '@/lib/graphon-search';
import { requireUser } from '@/lib/auth';

type Span = {
  key: string;
  versionId: string;
  unit: string;
  start?: number;
  end?: number;
  pages?: { start: number; end: number };
};
type SearchResponse = {
  results: { key: string; versionId: string | null; score: number; spans: Span[] }[];
  nextCursor: string | null;
  warnings: { code: string; message: string }[];
};

export async function POST(request: Request) {
  const user = await requireUser();
  const { query, cursor } = (await request.json()) as { query: string; cursor?: string };
  const body = await graphon<SearchResponse>('search', {
    target: BUCKET_ID,
    query,
    mode: 'hybrid',
    limit: 10,
    ...(cursor ? { cursor } : {}),
  });
  // Graphon answers from the whole bucket. Keep this tenant's keys only.
  const prefix = `orgs/${user.orgId}/`;
  return NextResponse.json({
    results: body.results.filter((result) => result.key.startsWith(prefix)),
    nextCursor: body.nextCursor,
    warnings: body.warnings,
  });
}
```

## An answer route with citations

```ts
// app/api/ask/route.ts
import { NextResponse } from 'next/server';
import { BUCKET_ID, graphon } from '@/lib/graphon-search';
import { requireUser } from '@/lib/auth';

type Span = {
  key: string;
  versionId: string;
  unit: string;
  start?: number;
  end?: number;
  pages?: { start: number; end: number };
};
type Turn = { role: 'user' | 'assistant'; content: string };
type AnswerResponse = {
  answer: string | null;
  sources: { ref: string; key: string; cited: boolean; span: Span }[];
  warnings: { code: string; message: string }[];
};

export async function POST(request: Request) {
  await requireUser();
  const { query, history } = (await request.json()) as { query: string; history: Turn[] };
  const body = await graphon<AnswerResponse>('answer', {
    target: BUCKET_ID,
    query,
    // Oldest first, at most 32 turns. Graphon stores none of them.
    history: history.slice(-32),
  });
  return NextResponse.json({
    answer: body.answer,
    sources: body.sources.filter((source) => source.cited),
    warnings: body.warnings,
  });
}
```

Render each `[[SRC:0001]]` marker in `answer` as a link to the source whose
`ref` is `SRC:0001`:

```tsx
const CITATION = /\[\[(SRC:\d{4})\]\]/g;

export function Answer({ answer, sources }: { answer: string; sources: Source[] }) {
  const parts = answer.split(CITATION);
  return (
    <p>
      {parts.map((part, index) =>
        index % 2 === 1 ? <Citation key={index} source={byRef(sources, part)} /> : part
      )}
    </p>
  );
}
```

## Stream a run

```ts
// app/api/research/[id]/events/route.ts
export async function GET(_: Request, { params }: { params: { id: string } }) {
  await requireUser();
  const upstream = await fetch(`${BASE}/research/${params.id}/events`, {
    headers: {
      authorization: `Bearer ${process.env.GRAPHON_API_KEY!}`,
      accept: 'text/event-stream',
      'last-event-id': '1',
    },
  });
  // The stream closes when the run ends. Pass it to the browser as it comes.
  return new Response(upstream.body, {
    headers: { 'content-type': 'text/event-stream', 'cache-control': 'no-store' },
  });
}
```

The browser reads it with `EventSource`. A `run.progress` event carries
`label`, `step`, and `totalSteps`. A `run.succeeded` event carries the
finished run with its answer and sources.
