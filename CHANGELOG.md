# Changelog

This plugin carries its own semver, separate from any Graphon service release.

- **Major** — a breaking change: a removed skill, a renamed MCP tool the
  skills call, or a changed install contract.
- **Minor** — a new skill, a new recipe, or a new capability.
- **Patch** — a fix to skill text, a manifest, or the hook, with no behavior
  change for a reader who already followed the skill.

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
