---
name: graphon-app-storage
description: Use when a task adds file uploads, downloads, file serving, avatars, attachments, or blob storage to application code, or replaces another storage provider such as S3, R2, GCS, Vercel Blob, Supabase Storage, Firebase Storage, or UploadThing with Graphon.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Storage in app code

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
costly. **Do not finish the job with the CLI instead.** The CLI can hold a
different account and a different environment, so the work would land
somewhere the user does not expect, and they would not be told.

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

The agent does not move the user's production bytes by hand. It writes code
that the app runs.

## Order of work

1. Make sure the app has a key. If `GRAPHON_API_KEY` is not where the app
   keeps its secrets, load `graphon-setup` and come back.
2. Create the bucket. One bucket per app and environment, for example
   `acme-uploads-dev`. Keep indexing enabled so the app can search it later.
   Load `graphon-storage` for the naming rules. Then set `GRAPHON_BUCKET` to
   the bucket name where the app keeps `GRAPHON_API_KEY` for that environment.
3. Write the client. Use the recipe for the stack in `references/`.
4. Write the upload path. Prefer a presigned `PUT` from the browser.
5. Write the serving path. Use a presigned `GET`, or a public bucket when the
   user asked for one.
6. Add a test that uploads a file and reads it back.

## Configuration

The app reads two values from its environment, because both change per
environment:

| Variable | Value | Secret |
| --- | --- | --- |
| `GRAPHON_API_KEY` | The key. It is both the Bearer token and the S3 secret. `graphon-setup` puts it where the app keeps its other secrets. | Yes |
| `GRAPHON_BUCKET` | The bucket name for this environment | No |

Everything else is a constant in the app's code. None of it is a secret:

| Value | Where it comes from |
| --- | --- |
| Workspace ID | `graphon workspaces get` |
| S3 endpoint | `https://<workspace id>.storage.beta.graphon.sh` |
| Graphon API origin, for search | `https://api.beta.graphon.ai` |

Never inline a key. Never send a key to the browser. One key per environment,
with the lowest role that works.

## The S3 client

Graphon speaks S3. Use the standard SDK for the language. Four settings are
not optional:

- The endpoint is the workspace host. The bare `https://storage.beta.graphon.sh`
  serves only the JSON API, so an S3 request there fails.
- `region` is `us-east-1`.
- Path-style addressing is on.
- The access key ID is the part of the key between the `_` and the `.`. The
  whole key is the secret.

```ts
// lib/graphon.ts. Only the key is a secret.
import { S3Client } from '@aws-sdk/client-s3';

// From `graphon workspaces get`.
const WORKSPACE_ID = '<workspace id>';
export const GRAPHON_API = 'https://api.beta.graphon.ai';

const key = process.env.GRAPHON_API_KEY!;
export const BUCKET = process.env.GRAPHON_BUCKET!;

export const graphon = new S3Client({
  endpoint: `https://${WORKSPACE_ID}.storage.beta.graphon.sh`,
  region: 'us-east-1',
  forcePathStyle: true,
  credentials: {
    accessKeyId: key.slice(key.indexOf('_') + 1, key.indexOf('.')),
    secretAccessKey: key,
  },
});
```

## Upload from the browser

Do not stream a user's file through the app server. The server signs a `PUT`
URL, and the browser uploads straight to storage.

1. The browser asks the server for an upload URL, naming the file and its type.
2. The server checks who the user is, builds the key, and signs the URL.
3. The browser `PUT`s the file to that URL.
4. The browser tells the server the upload finished, and the server saves the
   key in its database.

Save the **key** in your database, never the signed URL. A signed URL expires.

## Key layout

Put the tenant in the key, and never build a key from user input alone:

```
users/<userId>/avatar/<uuid>.<ext>
orgs/<orgId>/invoices/<year>/<uuid>.pdf
```

A key built from a filename lets one user overwrite another user's object.
Generate the id yourself and keep the original name in your database.

## Serving

- Private by default. Sign a `GET` URL when the user is allowed to read it.
- A public bucket suits assets that are safe for anyone with the link. Ask
  first, and say that every object in the bucket becomes readable.

## Recipes

Read the one that matches the stack:

| Stack | File |
| --- | --- |
| Next.js | `references/nextjs.md` |
| TanStack Start | `references/tanstack-start.md` |
| Express | `references/express.md` |
| FastAPI | `references/fastapi.md` |
| Django | `references/django.md` |
| Go | `references/go.md` |
| Replacing another provider | `references/replace-provider.md` |

## Finish

Run the project's tests. Then run `git diff` and read it. If any key appears
in the diff, stop, tell the user, and remove it before you continue.
