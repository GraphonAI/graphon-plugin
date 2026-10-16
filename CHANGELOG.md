# Changelog

This plugin carries its own semver, separate from any Graphon service release.

- **Major** — a breaking change: a removed skill, a renamed MCP tool the
  skills call, or a changed install contract.
- **Minor** — a new skill, a new recipe, or a new capability.
- **Patch** — a fix to skill text, a manifest, or the hook, with no behavior
  change for a reader who already followed the skill.

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
