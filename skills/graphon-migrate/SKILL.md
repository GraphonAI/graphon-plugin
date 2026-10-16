---
name: graphon-migrate
description: Use when the user asks to copy, upload, move, sync, import, migrate, or back up a folder, a directory, or many files into a Graphon bucket, or to bring data over from S3, R2, GCS, Azure Blob, MinIO, or another storage provider. Covers the inventory, the mapping plan, the bulk copy with graphon objects sync, and the check.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Move data into Graphon

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

Never delete the source. A migration ends when the user says it ended, not
when the copy finishes.

## 1. Inventory the source

Count the objects and the bytes before you move anything. Report both.

```bash
# A local folder
find ./data -type f | wc -l
du -sh ./data
```

For a bucket at another provider, the dry run in step 4 is the inventory. Its
first line counts the objects and bytes under the prefix, for example
`Found 120 objects (3.4 GiB) in s3://old-bucket/reports/.` Ask the user now for
the provider, the bucket, and the prefix.

Note anything that needs a decision: objects over 5 GiB, zero-byte objects,
and existing versions. Sync copies only the current version of each object.

## 2. Show a mapping plan and wait

Show the user a short table before you copy. Do not start until they agree.

| From                     | To                       |
| ------------------------ | ------------------------ |
| `./data/invoices/*.pdf`  | `acme-archive/invoices/` |
| `s3://old-bucket/users/` | `acme-uploads/users/`    |

State in one line: the object count, the total bytes, the target bucket, and
whether anything in the target will be overwritten.

## 3. Create the target bucket

Load `graphon-storage` for the naming rules. Turn versioning on when the
source has versions the user wants to keep.

## 4. Copy

Use `graphon objects sync` for every source. It already holds the login and
the workspace. It skips each object whose Graphon copy has the same size and
is newer, so a second run copies only what is new or changed, and a stopped
run restarts safely. It never deletes. Every byte passes through this machine,
so run it where the network is fast.

**From a local folder:**

```bash
graphon objects sync <bucket> --dir ./data --prefix <prefix> --dry-run
graphon objects sync <bucket> --dir ./data --prefix <prefix>
```

**From S3, R2, GCS, or MinIO**, name the source with
`--from s3://<source-bucket>/<prefix>`. Sync reads the source keys only from
these variables:

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: always.
- `AWS_SESSION_TOKEN`: only for temporary keys.
- `AWS_REGION`: the region of an AWS bucket. The default is `us-east-1`. When
  it is wrong, sync names the right one.

Never put a source key in a flag, and never print one. Each shell command
starts without the variables of the one before. When these variables are not
set in your shell, ask the user to put the source keys in a
`.env.graphon-source` file, and check that git ignores it with
`git check-ignore -q .env.graphon-source`. A user who signs in to AWS with a
profile or SSO can write that file with
`aws configure export-credentials --profile <name> --format env > .env.graphon-source`.
Then start each sync command with the line that loads the file:

```bash
set -a; . ./.env.graphon-source; set +a
graphon objects sync <bucket> --from s3://<source-bucket>/<prefix> --prefix <prefix> --dry-run
```

```bash
set -a; . ./.env.graphon-source; set +a
graphon objects sync <bucket> --from s3://<source-bucket>/<prefix> --prefix <prefix>
```

Add the source's endpoint:

| Source                      | Add                                                              |
| --------------------------- | ---------------------------------------------------------------- |
| AWS S3                      | nothing                                                          |
| Cloudflare R2               | `--from-endpoint https://<account id>.r2.cloudflarestorage.com`  |
| Google Cloud Storage        | `--from-endpoint https://storage.googleapis.com`, with HMAC keys |
| MinIO or another S3 service | `--from-endpoint <its URL>`                                      |

Run `--dry-run` first. Show the user the "Found" line, the count it would
upload, and the keys. Wait for a yes before the real run.

**From Azure Blob Storage**, which has no S3 API: copy the container to a
local folder first, for example with
`az storage blob download-batch --destination ./data --source <container> --account-name <account>`.
Then sync the folder with `--dir`.

When the migration ends, tell the user that `.env.graphon-source` holds the
source keys, so they can delete it.

## 5. Check

Run the same sync again with `--dry-run`. It must report
`Would upload 0, skipped <N>, failed 0.`, where `<N>` is the count from step 1:
the file count, or the number on the "Found" line. Sync skips only an object
whose Graphon copy has the same size, so this proves every object arrived with
its size. Each upload also sends the SHA-256 of every part it read, and
Graphon refuses a part whose bytes do not match.

Report any mismatch by key. Do not round up or summarize a failure as success.

When the target bucket has indexing enabled, check the indexing too:

```bash
graphon buckets index-status <bucket> --watch
graphon buckets index-status <bucket> --filter failed
graphon buckets index-status <bucket> --filter unsupported
```

Report the counts by state, and each file that failed or is unsupported, with
its error. Those files are stored but search will not return them.

## 6. Switch the app

Only after the check passes. Load `graphon-app-storage` and
`references/replace-provider.md`.

## 7. Leave the source alone

Tell the user the copy is verified and the source is untouched. Deleting the
source is their decision, in a later session, after their app has run on
Graphon.

## If the copy stops

A copy can stop partway. `graphon objects sync` prints `Failed <key>: <reason>`
for each object that failed, and exits `1`. Report the failed keys, then run
the same command again. It copies only what is left. For a provider source,
start it with the line that loads `.env.graphon-source` again.

When sync says that Graphon or the source refused the request, it stopped at
the first object, because every other object would fail the same way. Report
that line to the user. The fix is a key with the right access, not a rerun.
