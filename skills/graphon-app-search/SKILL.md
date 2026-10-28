---
name: graphon-app-search
description: Use when a task adds search, a search box, site search, document search, question answering, citations, retrieval, RAG, an AI chat over documents, or deep research to application code, where the files are stored in Graphon. Covers the search endpoint, the answer endpoint, a chat loop, a research stream, and per-user filtering.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Search in app code

These rules hold here, whether or not the `graphon` skill loaded:

- Do not print, echo, or paste an API key.
- When a shell exists, create an app key only with `graphon api-keys create`,
  and send the key to a file with `--write-env <path>` or pipe it into the
  project's secret manager. Never let the key reach the terminal. The
  `create_api_key` MCP tool puts the key in the transcript.
- Do not commit a `.env` file.
- Use the lowest role that does the job: `viewer`, then `editor`, then `admin`.
- Do not delete a bucket, an object, or source data unless the user asked for
  that exact delete in this session.
- When more than one Graphon MCP server is signed in, ask the user which one
  to use before the first write. The environment is in the tool name:
  `graphon` is production, and `graphon-qa` is a test environment.

The `graphon` skill explains what Graphon is, which interface to use, and how
to find the CLI. Load it with the Skill tool, not by reading its file.

## When you cannot continue

Each row below is a full stop. Say the sentence in the right column, then end
your turn. Do not run another command, and do not look for a way around it. A
blocked task that reports clearly is a good outcome; the user can unblock it
in seconds once they know what is wrong.

| When this happens | Say this, then stop |
| --- | --- |
| The Graphon CLI is missing and the install command fails | "I could not install the Graphon CLI. The installer exited with `<code>`: `<message>`." |
| `graphon whoami` fails twice | "I cannot confirm your Graphon login. Please run `graphon login` and tell me when it finishes." |
| No MCP tool and no Graphon CLI is available | "This session has no way to reach Graphon. Install the plugin's MCP server, or install the Graphon CLI." |
| The Graphon MCP server is listed but not signed in | "The Graphon MCP server is not signed in. Please authenticate it from your agent's MCP panel, then ask me again." |
| Five commands have run with no progress | "I am not making progress on this. Here is what I tried and what each command returned: `<list>`." |

The fourth row has one extra rule, because the mistake is easy to make and
costly. **Do not finish the job another way.** Do not use the CLI, and do not
use a second Graphon MCP server that is signed in. Either one can hold a
different account and a different environment, so the work would land
somewhere the user does not expect, and they would not be told. A signed-in
QA server is not a substitute for a production server that is not signed in.

Never do any of these, in any Graphon skill. When one of them is the only way
forward, that is a stop: say so and end your turn.

- Read, copy, print, or decode a credentials or token file, including anything
  under `~/.config/graphon/`. A token is a secret even when the user owns it.
  Say "I cannot inspect your stored credentials" and stop.
- Change permissions or ownership of any file or folder.
- Go looking through Graphon's own source, tests, or seed data to work around
  a failure. Reading the user's project to do the job they asked for is normal;
  reverse-engineering Graphon to get past an error is not.
- Try a second way to do something that just failed. One attempt, then report.
- Guess at an environment variable, a flag, or a config path that this skill
  does not name. If the skill does not name it, it does not exist.

Graphon indexes every file in a bucket with indexing enabled, so the app needs
no vector database, no embedding job, and no chunking code. The app sends one
HTTPS request for each question.

## Order of work

1. Make sure the app has a key. If `GRAPHON_API_KEY` is not where the app
   keeps its secrets, load `graphon-setup` and come back.
2. Make sure the bucket can answer. Load `graphon-search` for the index
   states, and check the bucket before you write code against it.
3. Write the client. One file holds the origin, the workspace id, and the key.
4. Write the endpoints the app needs: search, answer, or research.
5. Filter by user. Graphon answers from the whole bucket.
6. Add a test that indexes one file and asks one question about it.

## Configuration

| Value | Where it comes from | Secret |
| --- | --- | --- |
| `GRAPHON_API_KEY` | `graphon-setup` puts it where the app keeps its secrets | Yes |
| `GRAPHON_BUCKET_ID` | `graphon buckets get <bucket>` | No |
| Workspace id | `graphon workspaces get` | No |
| API origin | `https://api.beta.graphon.ai` | No |

A `viewer` key is enough for all three operations. Never send the key to the
browser. Every call goes from the app's server.

## The client

```ts
// lib/graphon-search.ts. Only the key is a secret.
const WORKSPACE_ID = '<workspace id>';
const BASE = `https://api.beta.graphon.ai/v1/workspaces/${WORKSPACE_ID}`;

export const BUCKET_ID = process.env.GRAPHON_BUCKET_ID!;

export async function graphon<T>(route: string, body: unknown): Promise<T> {
  const response = await fetch(`${BASE}/${route}`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${process.env.GRAPHON_API_KEY!}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Graphon ${route} failed: ${response.status}`);
  }
  return (await response.json()) as T;
}
```

## The three routes

| Route | Body | Returns |
| --- | --- | --- |
| `POST /search` | `bucketId`, `query`, `mode`, `resultUnit`, `limit`, `cursor`, `keys`, `keyPrefix` | Ranked results, each with a key, a version, and the places that matched |
| `POST /answer` | `bucketId`, `query`, `history`, `image`, `keys`, `keyPrefix` | 200 with one answer with `[[SRC:0001]]` markers and its sources |
| `POST /research` | `bucketId`, `query`, `history`, `keys`, `keyPrefix` | A run id at once. Read its events, then its answer. |

## A search endpoint

Send the user's text, return the keys and the places. Do not return the key to
the browser as a link. Sign a download URL only when the user opens a result,
so an expired link never sits in the page.

Keep `limit` at 10 for a search box. Page with `nextCursor`, which works for
40 minutes. Leave `mode` at `hybrid` for most searches. Use `mode: 'keyword'`
for exact words, such as an ID, a code, or an error message.

## An answer endpoint

Return the answer text and the sources together. Render each `[[SRC:0001]]`
marker as a link to the source whose `ref` is `SRC:0001`. A source carries the
key, the version, and the place, so the link can open the file at its page or
its time range. When the object version is gone, `versionId` and `span` are
null: show the key with no link.

A source with `cited` false was read but not cited. Keep it out of the
footnotes.

When `answer` is null, show the warning, not an empty box. `index_empty` means
the bucket has nothing indexed yet.

The call waits for the answer and returns 200. Graphon stores nothing from
it: the response has no id, and no call reads the answer again. Store the
answer and its sources in the app if you need them later. Send `keys` or
`keyPrefix` to answer from some of the bucket's objects instead of all of
them.

## A chat loop

The app owns the conversation. Graphon keeps no conversation of its own, and
an answer stores nothing, so the turns must come from the app each time.

1. Keep the turns in the app's database or session.
2. Send them in `history`, oldest first, at most 32 turns, each one `user` or
   `assistant`.
3. Append the new answer to the history for the next turn.
4. With an image question, store the `imageDescription` that comes back and
   send it as an assistant turn. The picture does not go again.

## A research endpoint

`POST /research` returns a run id at once. The run takes minutes, so the
browser must not wait on one request.

1. Start the run on the server and give the run id to the browser.
2. Read `GET /research/<id>/events` as server-sent events, and push each
   progress event to the browser.
3. On the last event, store the answer and its sources.
4. Read `GET /research/<id>` when a browser rejoins. The run stays readable
   until its `expiresAt`. Read that field; do not assume a number.

## Per-user results

Graphon answers from the whole bucket. One tenant's question can reach another
tenant's file. Keep tenants apart:

- Put the tenant in the key, and one bucket per tenant where the data must
  never mix.
- Filter the results by key prefix on the server, before they reach the user.
- Never take `bucketId` from the browser. The server decides which bucket the
  signed-in user may read.

## Recipes

| Stack | File |
| --- | --- |
| Next.js | `references/nextjs.md` |
| Express | `references/express.md` |
| FastAPI | `references/fastapi.md` |

## Finish

Run the project's tests. Then run `git diff` and read it. If any key appears
in the diff, stop, tell the user, and remove it before you continue.
