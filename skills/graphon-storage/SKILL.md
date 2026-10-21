---
name: graphon-storage
description: Use when a task creates, changes, inspects, shares, or deletes Graphon buckets or objects. Covers bucket settings, naming rules, reading and writing objects, presigned upload and download URLs, and the confirm rule for deletes.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Buckets and objects

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

## Pick the interface

| Job | Use |
| --- | --- |
| Create, list, inspect, or change a bucket | MCP tools |
| Write content you generated, up to 1 MiB | `write_object` |
| Upload a file from disk | the CLI, or `create_object_upload_url` |
| Upload a folder | `graphon objects sync` |
| Download a file to disk | the CLI, or `create_object_download_url` |
| Read a file into the conversation | `read_object` |
| Give a browser or another service a direct link | a presigned URL |

## Bucket names

- 1 to 255 ASCII letters, digits, periods, underscores, or hyphens.
- Not exactly `.` or `..`.
- Case-sensitive: `Reports` and `reports` are two buckets.
- Unique within the workspace, not across Graphon.

Call `check_bucket_name` before you create one, and offer a second name when
it is taken. A bucket can be renamed later. The rename keeps its ID and its
objects.

## Bucket settings

A new bucket is **private** and has **indexing enabled**.

| Setting | Meaning | Change it when |
| --- | --- | --- |
| Indexing | Graphon indexes each object so that search, answers, and research can use it | Keep it on. Turn it off only when the user asks for storage only. It is fixed when the bucket is created. |
| Private read | Only a key or a presigned URL reads an object | The default. Keep it. |
| Public read | Anyone with the URL reads an object | The user asked for a public asset host, and said so in this session |
| Versioning | A write keeps the old version | The user wants undo, or an audit trail |
| Retention | An object cannot be deleted for a set time | The user named a compliance rule |

Indexing cannot be turned on later. To search a bucket made without it, copy
its objects into a new bucket.

In a bucket with indexing, each object version shows its indexing state:
`preparing`, `sending`, `queued`, `indexing`, `ready`, `failed`, or
`unsupported`. `list_objects`, `get_object_metadata`, and `graphon objects
stat` show it. `get_bucket_index_status` and `graphon buckets index-status`
show the whole bucket.

Turning on public read exposes every object in the bucket. Say that in one
line and wait for the user to confirm before you change it.

## Create a bucket

`create_bucket` and `graphon buckets create` take a name alone.

```bash
graphon buckets create support-tickets
graphon buckets create support-tickets --provider r2 --location wnam
graphon buckets locations
```

Three settings are fixed when the bucket is created: indexing, provider, and
location. A call that omits them gets indexing enabled, provider `gcp`, and the
US multi-region. The CLI prints the three values, and `create_bucket` returns
them.

Name the provider and the location in your report, and say that the user can
choose others. Do not ask first. Ask only when the user named a region, a
country, a compliance rule, or a cloud they already use. Then run
`graphon buckets locations` and offer the locations of that provider.

## Objects

Use `list_objects` with a `prefix` to page through a folder. Treat the key as
a path: `users/42/avatar.png`. There are no real folders, only key prefixes.

`write_object` takes content you produce, up to 1 MiB, with an `encoding` of
`utf8` or `base64`. For a file on disk, call `create_object_upload_url` and
`PUT` the bytes, or run the CLI:

```bash
graphon objects put <bucket> <key> --file ./local/path.pdf
graphon objects get <bucket> <key> --output ./local/path.pdf
graphon objects list <bucket> --prefix users/42/
graphon objects sync <bucket> --dir ./local/folder --prefix users/42/ --dry-run
```

`graphon objects sync` uploads the new and changed files of a folder and never
deletes an object. Run it with `--dry-run` first and show the user the list.

`read_object` returns text up to `maxBytes`, returns a PNG, JPEG, GIF, or WebP
as an image, and returns a download URL for anything larger or any other type.

## Presigned URLs

- `create_object_upload_url` gives a `PUT` URL, so a browser uploads straight
  to storage and the bytes never cross the app server.
- `create_object_download_url` gives a `GET` URL for a private object.
- `create_object_replace_url` gives a `PUT` URL for an object that already
  exists.

A presigned URL expires. Generate it when the client asks for it, not ahead of
time, and never commit one.

## Deletes

Never delete unless the user asked for that exact delete in this session.

`delete_bucket` and `empty_bucket` take `confirmName`: the exact bucket name,
again. The CLI uses `--confirm-name`. This is a guard, not a formality. Read
the name back to the user before you send it.

```bash
graphon buckets empty <name> --confirm-name <name>
graphon buckets delete <name> --confirm-name <name>
```

A bucket must be empty before it can be deleted. A deleted bucket stays
restorable for seven days. An object under retention is not emptied, and the
call returns `object_locked` with the keys that stayed.

## Report

Say what you did in plain terms: the bucket, the key, the size, and the
version when versioning is on. Give the user the console link, not a key.
