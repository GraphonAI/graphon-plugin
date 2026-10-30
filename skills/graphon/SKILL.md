---
name: graphon
description: Use when the user names Graphon, or when a task needs file storage, object storage, uploads, downloads, S3, a bucket, a place to keep app data or user files, or search, answers, or research over stored files or over a dataset that Graphon curates. Explains what Graphon is, which interface to use, how to find the CLI, and which Graphon skill to load next.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Graphon

Graphon is object storage with search built in. A bucket holds files. A file
is an object, named by a key such as `docs/a.pdf`. A workspace is the account
that owns the buckets. A bucket with indexing enabled can also be searched.

Graphon serves three APIs:

- The S3 API, on the workspace host `https://<workspace id>.storage.beta.graphon.sh`.
  Use it from any S3 SDK or tool.
- The JSON storage API, on `https://storage.beta.graphon.sh`. It does not answer S3
  requests.
- The Graphon API, on `https://api.beta.graphon.ai`. It serves search, answers, research,
  API keys, and members.

## Choose the interface first

| Use | For | Why |
| --- | --- | --- |
| MCP tools | Buckets, keys, members, search, and objects up to 1 MiB | No shell needed. Works in every chat client. |
| The `graphon` CLI | Local files, folder upload, putting a key where the app keeps secrets | The MCP server cannot read the user's disk, and a key must not pass through the model. |
| An SDK or HTTP client in the user's code | Anything the user's app does at run time | An app needs a library, not an agent. |

Read a file from disk? Use the CLI. Write content you generated? Use
`write_object`. Add uploads or search to an app? Write code against the APIs.

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

## Find the CLI

Run `graphon --version`. If that fails, try `~/.local/bin/graphon --version`
and use that full path for every later call.

If both fail, run the install **once**:

```bash
curl -fsSL https://beta.graphon.ai/install.sh | sh -s -- --no-modify-path --quiet
```

Then run `~/.local/bin/graphon --version` again. If it still fails, stop. Tell
the user the CLI is not installed and show the install command. Do not search
for another copy, another installer, or a source checkout.

## Check for a login

Run `graphon whoami`. It prints the signed-in user and the current workspace.
If it fails, load `graphon-setup`.

`graphon workspaces get` prints the ID of the selected workspace. Use it
wherever a Graphon skill says `<workspace id>`. Do not store the workspace
anywhere else: the CLI already keeps it.

## Search, answer, and research

A bucket with indexing enabled can be read three ways. Use the MCP tools, or
the CLI, or the Graphon API from app code: send the key as a Bearer token to
`https://api.beta.graphon.ai`. A viewer key is enough.

| Job | MCP tool | API route, under `/v1/workspaces/<workspace id>` |
| --- | --- | --- |
| Find a dataset that Graphon curates | `list_datasets`, `get_dataset` | `GET /datasets`, `GET /datasets/<dataset id>` |
| Rank objects or passages | `search_objects` | `POST /search` |
| Answer with citations | `answer_question` | `POST /answer` |
| Deep research | `start_research`, `get_research` | `POST /research`, `GET /research/<run id>` |

Graphon also curates read-only datasets, such as case law, that every
workspace can query. Find one with `list_datasets` or `graphon datasets list`,
then send its dataset id (`dst…`) where a call takes a bucket.

A file answers only after it finishes indexing. Check the bucket first:

```bash
graphon buckets index-status <bucket> --watch
```

Load `graphon-search` before you run any of them.

## Load the next skill

| The task | Load |
| --- | --- |
| Set up Graphon in this project, or no login or key was found | `graphon-setup` |
| Create, change, inspect, share, or delete buckets or objects | `graphon-storage` |
| Search, ask a question about, chat with, or research stored files or a dataset | `graphon-search` |
| Add uploads, downloads, file serving, or blob storage to app code | `graphon-app-storage` |
| Add search, answers, chat, or research to app code | `graphon-app-search` |
| Move, copy, import, or back up data into Graphon | `graphon-migrate` |
| A Graphon call failed | `graphon-troubleshoot` |

## Roles

A member holds one role in a workspace.

| Role | Can |
| --- | --- |
| `viewer` | Read buckets and objects, and search them |
| `editor` | Everything a viewer can, plus write and delete objects, and create buckets |
| `admin` | Everything an editor can, plus manage members, API keys, and the workspace |

An API key carries its own role, capped by the role of the member who made it.
