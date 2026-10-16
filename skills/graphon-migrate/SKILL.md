---
name: graphon-migrate
description: Use when the user asks to copy, upload, move, sync, import, migrate, or back up a folder, a directory, or many files into a Graphon bucket, or to bring data over from S3, R2, GCS, Azure Blob, MinIO, or another storage provider. Covers the inventory, the mapping plan, the bulk copy, and the checksum check.
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

# An S3-compatible source
aws s3 ls s3://bucket --recursive --summarize | tail -3
```

Note anything that needs a decision: objects over 5 GiB, keys with characters
that need encoding, zero-byte objects, and existing versions.

## 2. Show a mapping plan and wait

Show the user a short table before you copy. Do not start until they agree.

| From | To |
| --- | --- |
| `./data/invoices/*.pdf` | `acme-archive/invoices/` |
| `s3://old-bucket/users/` | `acme-uploads/users/` |

State in one line: the object count, the total bytes, the target bucket, and
whether anything in the target will be overwritten.

## 3. Create the target bucket

Load `graphon-storage` for the naming rules. Turn versioning on when the
source has versions the user wants to keep.

## 4. Copy

**From a local folder**, use the CLI. It already holds the login and the
workspace. A second run skips every file whose object has the same size and is
newer, so it restarts safely.

```bash
graphon objects sync <bucket> --dir ./data --prefix <prefix> --dry-run
graphon objects sync <bucket> --dir ./data --prefix <prefix>
```

Run `--dry-run` first and show the user what it would upload.

**From S3, GCS, Azure, or R2**, use `rclone`. It restarts where it stopped.
Every byte passes through this machine, so run it where the network is fast.

Make one key for the copy, in a git-ignored file. When
`.env.graphon-migration` already exists, use it and do not make another key:

```bash
test -f .env.graphon-migration || graphon api-keys create --name "migration" --role editor --write-env .env.graphon-migration
```

Each shell command starts without the variables of the one before. So start
every shell command that names `graphon:` with these setup lines, in that same
command. They load the key and define the `graphon:` remote through
environment variables, so the key never enters a config file or the
transcript:

```bash
set -a; . ./.env.graphon-migration; set +a
export RCLONE_CONFIG_GRAPHON_TYPE=s3
export RCLONE_CONFIG_GRAPHON_PROVIDER=Other
export RCLONE_CONFIG_GRAPHON_ENDPOINT="https://$(graphon workspaces get).storage.beta.graphon.sh"
export RCLONE_CONFIG_GRAPHON_REGION=us-east-1
export RCLONE_CONFIG_GRAPHON_FORCE_PATH_STYLE=true
export RCLONE_CONFIG_GRAPHON_ACCESS_KEY_ID="$(printf %s "$GRAPHON_API_KEY" | cut -d_ -f2- | cut -d. -f1)"
export RCLONE_CONFIG_GRAPHON_SECRET_ACCESS_KEY="$GRAPHON_API_KEY"
```

Then, in the same command as the setup lines:

```bash
rclone copy source:old-bucket graphon:<bucket>/<prefix> --progress --checksum
```

Use `copy`, never `sync`. `rclone sync` deletes from the target to match the
source, and a wrong path then destroys data. When the migration ends, tell the
user the key name `migration`, so they can revoke it.

## 5. Check

Check all three. A count alone does not prove the bytes arrived. Run these in
one command that starts with the setup lines from step 4.

```bash
# Counts
rclone size source:old-bucket
rclone size graphon:<bucket>/<prefix>

# Per-object checksums
rclone check source:old-bucket graphon:<bucket>/<prefix> --checksum
```

For a local source, run the same `graphon objects sync` with `--dry-run`
again. It must report `Would upload 0`. Then compare the file count with
`graphon objects list <bucket> --prefix <prefix>`.
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

A copy can stop partway. `graphon objects sync` reports each file that
failed and exits `1`. Report the failed keys. Both `graphon objects sync` and
`rclone copy` restart from where they stopped, so the fix is to run the same
command again. For `rclone copy`, start it with the setup lines from step 4
again. Do not make another key.
