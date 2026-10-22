---
name: graphon-search
description: Use when a task searches, queries, asks a question about, chats with, or researches files that are stored in Graphon, or when the user wants to find a document, get an answer with citations, or run deep research over a bucket. Covers search, answers, chat turns, research runs, and the index states that decide what a bucket can answer.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Search, answers, and research

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

A bucket with indexing enabled can be read three ways. Each call names one
bucket, and Graphon reads the whole bucket unless the call scopes it with
`keys` or `keyPrefix`.

## Choose the operation

| The user wants | Use | Time |
| --- | --- | --- |
| Files or passages to read, open, or list | `search_objects` | Under a second to a few seconds |
| One written answer, with citations | `answer_question` | Seconds, at most 120 |
| A question that needs many reads, or every match | `start_research` | Minutes, at most 600 seconds |

Search first when you must read the files yourself. Ask when the user wants
the answer, not the files. Research only when a Standard answer is not
enough, because it is premium and slow.

## Check the bucket first

Indexing is fixed when a bucket is created. A bucket made without it never
answers, and the error is `indexing_disabled`.

A file answers only after it finishes indexing:

```bash
graphon buckets index-status <bucket> --watch
graphon buckets index-status <bucket> --filter failed
graphon buckets index-status <bucket> --filter unsupported
```

The MCP tool is `get_bucket_index_status`. Report every `failed` and
`unsupported` key to the user, because no search will ever return it. While a
new version of a file indexes, its older version still answers.

## Search

`search_objects` takes the bucket, the text, and four options:

| Option | Values | Use |
| --- | --- | --- |
| `mode` | `standard` (the default), `fast` | `standard` reranks the top results. `fast` skips the reranker. |
| `resultUnit` | `object` (the default), `passage` | `object` gives one result for each file, with up to 3 places. `passage` gives one result for each place. |
| `limit` | 1 to 100, 10 by default | Keep it small. Read the best results first. |
| `cursor` | `nextCursor` from the page before | Send the same body with it. It works for 40 minutes. |
| `keys` | At most 50 object keys | Read only these objects. `answer_question` and `start_research` take it too, and the CLI takes `--key`. |
| `keyPrefix` | A key prefix, such as `videos/2026/` | Read only the objects whose key begins with it. With `keys`, an object must match both. The CLI takes `--prefix`. |

Both modes match exact words and meaning together. A result holds the key, the
version, and each place that matched: a page of a document, a time range in a
recording, or a path in a JSON file. Pages count from 0, so page 0 is the
first page. Give the page as it is.

Search gives you the key. Read the file with `read_object`, or give the user a
link with `create_object_download_url`. From a shell:

```bash
graphon search <bucket> "connection pool exhausted" --mode fast --limit 20
graphon search <bucket> "connection pool exhausted" --unit passage
```

## Answers and chat

`answer_question` returns one answer and its sources on the same call.

- The answer holds a `[[SRC:0001]]` marker for each citation. The source whose
  `ref` is `SRC:0001` is the file it came from. Keep the markers when you show
  the answer, and name the file for each one.
- A source with `cited` false was read but not used. Do not present it as
  evidence.
- For a chat, send the earlier turns in `history`, oldest first, at most 32.
  Graphon keeps no conversation of its own, so the turns must come from you
  each time. The turns you send are stored on the run that answers them.
- An image question is premium. Send the picture in `image`. The reply holds
  `imageDescription`. Send that description in the next turn's `history`, and
  the picture does not go again.
- A null answer with the warning `index_empty` or `index_failed` means the
  bucket had nothing to answer from. Say so. Do not guess an answer.

```bash
graphon ask <bucket> "Why did checkout stall after the 3 October deploy?"
graphon chat <bucket>
```

`graphon chat` answers one question for each line of its input and sends the
earlier turns with each one. Give it the questions on standard input when you
run it for a user, because it reads a terminal and a pipe the same way.

## Research

`start_research` researches one bucket in depth. It searches, reads, then
searches again inside the bucket with what it learned. It takes no mode.
Research is premium.

A question that asks for every match, such as "find all the incidents" or
"every time checkout timed out", goes to `start_research`, not
`answer_question`.

The tool follows the run and returns it when it ends. Its first progress
notification names the run id. If your call ends before the run does,
read the run with `get_research`. A finished run stays readable until its
`expiresAt`, then it is gone. Read `expiresAt`; do not assume a number.

```bash
graphon research start <bucket> "Every checkout timeout this quarter" --watch
graphon research get <researchId>
```

`--watch` prints each step until the answer arrives. Without it, the command
prints the run id at once.

## Keep up to date

For app code that must act when a file becomes searchable, register a webhook
with `create_webhook` for `object.indexed` and `object.indexing_failed`.
Register only a URL that the user gave you.

## Report

Say which bucket you read, which operation you used, and what it cost in time.
List each source by key, with its page or time range. When a warning came
back, give it to the user in plain words, with the next step.

Read the reference before you write app code against these routes:

- `https://docs.beta.graphon.ai/api/search/search-objects.md`
- `https://docs.beta.graphon.ai/api/answer/answer-question.md`
- `https://docs.beta.graphon.ai/api/research/start-research.md`

To put search, answers, or chat into the user's own app, load
`graphon-app-search`.
