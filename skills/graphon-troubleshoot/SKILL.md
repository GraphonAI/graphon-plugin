---
name: graphon-troubleshoot
description: Use when a Graphon call fails, a Graphon MCP tool returns an error, the Graphon CLI exits non-zero, or an S3 request against Graphon returns 403, 501, or an unexpected status. Maps each error to its cause and its fix.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# When a Graphon call fails

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

Read the error code before you change anything. Do not retry a failing call
with the same inputs, and do not widen a role to make an error go away.

## MCP tool errors

| Code | Cause | Fix |
| --- | --- | --- |
| `workspace_required` | The caller belongs to several workspaces and the tool got no `workspaceId` | Call `list_workspaces`, ask the user which one, then pass `workspaceId` |
| `unauthenticated` | No credential, or the token expired | The agent signs in again. Do not ask the user for a key. |
| `forbidden` | The key's role is below the tool's role | Say which role the tool needs. Do not create a wider key without asking. |
| `insufficient_scope` | An OAuth grant is below the tool's role | The user approves more access on the consent page |
| `not_found`, `object_not_found`, `resource_not_found` | The bucket or key does not exist in this workspace | Check the workspace first, then list with a prefix. A key is case-sensitive. |
| `result_too_large` | The result passed 100,000 characters | Narrow it: add a `prefix`, lower `maxBytes`, or page with a cursor |
| `request_too_large` | The request body passed 2 MiB | Use `create_object_upload_url` instead of `write_object` |
| `content_too_large`, `entity_too_large` | The object passed the inline 1 MiB limit | Use `create_object_upload_url` |
| `object_locked` | Retention still covers the object | Report the keys. Retention cannot be bypassed. |
| `storage_quota_exceeded` | The workspace allowance is used up | Report the last key written. The user raises the allowance, then the same command restarts. |
| `rate_limited` | Over 300 tool calls per minute | Wait, then batch the work. Do not loop faster. |

## Search, answer, and research errors

| Code | Cause | Fix |
| --- | --- | --- |
| `indexing_disabled` | The bucket was made without indexing | Search another bucket. Indexing cannot be turned on later. |
| `index_not_ready` | No object in the bucket has finished indexing | Run `graphon buckets index-status <bucket> --watch`, or call `get_bucket_index_status`, until a version is `ready`. Then ask again. |
| Search does not return a file you uploaded | The file has not finished indexing, or it failed | Run `graphon buckets index-status <bucket> --filter failed`, then `--filter unsupported`. Report each key and its error. |
| `bucket_not_ready` | The bucket is still being created | Call `get_bucket` until its phase is `active` |
| `bucket_offline` | An editor took the bucket offline | An editor must bring it online first |
| `feature_not_in_plan` | Research and image questions are premium | Tell the user which feature the workspace plan lacks |

A search with a warning returns no results, and it is not an error:

- `index_empty`: the bucket has nothing indexed yet. Upload files, or wait for
  indexing to finish.
- `index_failed`: every object in the bucket failed to index. Run
  `graphon buckets index-status <bucket> --filter failed`, or call
  `get_bucket_index_status`, and report each key and its error.

## CLI exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | The API or the network failed |
| 2 | Wrong usage: a missing flag, a bad value, or an unknown command |
| 130 | The user pressed Ctrl-C |

Run `graphon doctor` first. It prints the version, the install path, the
environment, and whether a login is stored, and it makes no network call.

## S3 errors

| Status | Cause | Fix |
| --- | --- | --- |
| Any error from `https://storage.beta.graphon.sh` | The bare storage host serves only the JSON API | Use the workspace host, `https://<workspace id>.storage.beta.graphon.sh`, with the ID from `graphon workspaces get` |
| 403 `SignatureDoesNotMatch` | Wrong credentials or wrong signing settings | Set `region` to `us-east-1`, turn on path-style addressing, and use SigV4. The access key ID is the part of the key between the `_` and the `.`. The whole key is the secret. |
| 403 on a presigned URL | The URL expired | Sign a new one per request. Do not cache or commit a signed URL. |
| 403 with a correct key | The clock is off | Check the system clock. More than 15 minutes of skew fails every signature. |
| 401, or 403 `SignatureDoesNotMatch`, after the key went into a secret manager | The stored key ends in a newline | Store it again through `tr -d '\n'`. See `graphon-setup`. |
| 404 | The bucket or key does not exist | A key is case-sensitive and has no leading slash |
| 501 `NotImplemented` | The operation is not available | See below |

`501` is not a bug to work around. Graphon returns it for multiple byte
ranges, for a copy across providers, and for object stores that are not
available yet. Report what is not available and offer the supported path:
download and re-upload instead of a cross-provider copy, and one range instead
of several.

## Common mistakes

- **A key in the transcript.** If a key was printed, tell the user to revoke it
  with `graphon api-keys revoke <keyId>`, then load `graphon-setup` to put a
  new one where the app keeps its secrets.
- **Path-style off.** The SDK defaults to virtual-host style and the request
  reaches the wrong host. Turn `forcePathStyle` on.
- **The wrong workspace.** `graphon workspaces current` shows the selected one.
- **A leading slash in a key.** `/users/1/a.png` and `users/1/a.png` are
  different objects.

## If none of this fits

Collect the exact command, the exact error, `graphon doctor` output, and the
request id when the error carries one. Give those to the user. Do not guess at
a cause, and do not change the user's bucket settings to test a theory.
