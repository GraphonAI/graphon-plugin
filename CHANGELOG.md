# Changelog

This plugin carries its own semver, separate from any Graphon service release.

- **Major** — a breaking change: a removed skill, a renamed MCP tool the
  skills call, or a changed install contract.
- **Minor** — a new skill, a new recipe, or a new capability.
- **Patch** — a fix to skill text, a manifest, or the hook, with no behavior
  change for a reader who already followed the skill.

## 2.0.0

- `get_research` is now `get_run`, and it reads a run of any mode. Every
  question answers as a query run, so `answer_question` and `start_research`
  both produce a run that `get_run` reads until it expires.
- A finished run stays readable until its `expiresAt`, not one hour: one
  day for an answer, seven days for research.
- `result_too_large` now carries `retryWith`: the call that returns a smaller
  result. For a run it names `get_run` with the cited sources only.
- `search_objects`, `answer_question`, and `start_research` take `keys` and
  `keyPrefix`, so a question can be scoped to some objects of a bucket
  instead of naming a file inside the question text.
- A slow tool now reports progress while it works, so a client no longer
  drops the call before the answer arrives.

## 1.3.1

- The search skill now says which research mode answers a question that asks
  for every match. A question that starts with "find all", "list every", or
  one of the other openings wants `recall`.

## 1.3.0

- The plugin and the MCP server now name their environment. A non-production
  build installs under its own plugin name and its own MCP server key, so two
  installs can no longer shadow each other, and the tool names in a session
  show which environment a call reached.
- A non-production server states that it is a test environment when an agent
  connects, and again on the result of any call that writes. A production
  server adds nothing to either.
- When more than one Graphon server is signed in, an agent now asks which one
  to use before its first write. A single signed-in server behaves as before.
- Production installs keep the name `graphon` and need no action. An install
  of a non-production build made before this version sits under the old
  shared name. Remove it and add it again.

## 1.2.1

- The README says that the CLI searches a bucket, answers a question from it,
  holds a chat, and runs research. It named only files, folders, and keys
  before. No skill changed, so an agent behaves as it did in 1.2.0.

## 1.2.0

- Two new skills for retrieval: `graphon-search` runs search, answers, chat
  turns, and research over a bucket. `graphon-app-search` writes a search
  endpoint, an answer endpoint with citations, a chat loop, and a research
  stream into the user's app, with recipes for Next.js, Express, and FastAPI.
- The `graphon` skill routes to both, and keeps one short table of the three
  operations.
- The skills name the new CLI commands `graphon search`, `graphon ask`,
  `graphon chat`, `graphon research start`, and `graphon research get`.
- `graphon-troubleshoot` covers a research run that expired, and the indexing
  message that the new commands print.

## 1.1.0

- `graphon-migrate` copies from S3, R2, GCS, and MinIO with
  `graphon objects sync --from`. It no longer needs rclone or a second API
  key. The source keys come from `AWS_ACCESS_KEY_ID` and
  `AWS_SECRET_ACCESS_KEY`.
- `graphon-migrate` copies Azure Blob Storage to a local folder first, then
  syncs the folder.
- The check after a copy is a second dry run that must report nothing left to
  upload.

## 1.0.0

First release.

- Six skills: `graphon`, `graphon-setup`, `graphon-storage`,
  `graphon-app-storage`, `graphon-migrate`, `graphon-troubleshoot`.
- Seven app recipes: Next.js, TanStack Start, Express, FastAPI, Django, Go,
  and replacing another storage provider.
- The Graphon MCP server, registered from `.mcp.json`.
- A session start hook that installs the Graphon CLI when it is missing, and
  adds it to the session PATH.
