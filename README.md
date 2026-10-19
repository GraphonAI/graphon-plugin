# Graphon plugin for coding agents

Object storage with search your coding agent can set up, fill, query, and wire
into your app.

This plugin gives your agent three things:

- **The Graphon MCP server.** Typed tools for workspaces, API keys, members,
  buckets, objects, and search. Your agent signs in with OAuth on its first call.
- **The Graphon CLI.** The agent uploads local files, syncs folders, and puts
  API keys where your app keeps its secrets, so a key never reaches the
  transcript. It also searches a bucket, answers a question from it, holds a
  chat about it, and runs research.
- **Graphon skills.** Instructions that teach the agent how to build app storage
  and search on Graphon, search and question your files, move data in, and run
  day-to-day storage work.

Version 1.3.1. MCP server: `https://api.beta.graphon.ai/mcp`.

## Install

One command, every agent on the machine:

```bash
npx plugins add GraphonAI/graphon-plugin
```

That installs the whole plugin — skills and the MCP server — into each agent it
finds. For an agent that takes skills only:

```bash
npx skills add GraphonAI/graphon-plugin
```

### Per agent

| Agent | Status | Install |
| --- | --- | --- |
| Claude Code | Verified | `claude plugin marketplace add GraphonAI/graphon-plugin`<br>`claude plugin install graphon@graphon --scope user` |
| Codex | Verified | `codex plugin marketplace add GraphonAI/graphon-plugin`<br>`codex plugin add graphon@graphon` |
| Cursor | Verified | `npx plugins add GraphonAI/graphon-plugin`<br>A Cursor marketplace listing is pending review. |
| Gemini CLI | Blocked upstream | `gemini extensions install https://github.com/GraphonAI/graphon-plugin --consent`<br>Gemini Code Assist no longer signs in individual accounts, so the extension installs but cannot connect. Skills still work through `npx skills add`. |
| Antigravity IDE | Verified | `npx skills add GraphonAI/graphon-plugin`<br>Copy mcp/antigravity.json to ~/.codeium/antigravity/mcp_config.json, restart, then sign the server in from the MCP panel: Antigravity does not prompt for that on its own. The tools work once signed in. The skills load but this agent does not reliably follow their stop rules, so approve its commands one at a time. The Antigravity CLI does not surface MCP tools yet. |
| Copilot CLI | Verified | `copilot plugin marketplace add GraphonAI/graphon-plugin`<br>`copilot plugin install graphon@graphon`<br>If MCP tools are missing, your organization may block third-party MCP servers. Check github.com/settings/copilot. The skills work either way. |
| Another agent | Should work | `npx plugins add GraphonAI/graphon-plugin`<br>`npx add-mcp https://api.beta.graphon.ai/mcp` |

**Verified** means a real session connected, called a tool, and the call
was recorded. **Should work** means the manifest ships and validates, but
nobody has loaded it yet. **Blocked upstream** means the agent itself
cannot connect today, for a reason outside this plugin.

## Search, ask, chat and research

A bucket with indexing enabled can be read three ways, from the MCP tools, the
CLI, or your own code:

| Job | CLI |
| --- | --- |
| Rank the objects that match a text | `graphon search <bucket> "<text>"` |
| One answer with a citation for each source | `graphon ask <bucket> "<question>"` |
| A chat, where a follow-up can say "it" | `graphon chat <bucket>` |
| A deep run that works on its own | `graphon research start <bucket> "<question>" --watch` |

Indexing is fixed when a bucket is created, and an object answers only after it
finishes indexing. `graphon buckets index-status <bucket> --watch` shows how far
that has come. The skills tell the agent to check this before its first search.

## What your agent can do

Ask it in your own words:

- "Set up Graphon storage in this project."
- "Move this app's file uploads to Graphon."
- "Add search over my documents to this app."
- "Ask my Graphon bucket why checkout stalled last week."
- "Copy my S3 bucket into Graphon and check every file."

The skills teach the agent which interface fits each job. It uses MCP tools for
buckets, keys, members, and questions. It uses the CLI for local files and for
secrets. It writes an SDK call into your app for anything your app does at run
time.

## Keys and safety

The plugin stores no credential. The MCP server signs the agent in with OAuth,
and you approve the connection on a Graphon consent page. You can disconnect
the agent at any time in Settings, under Security.

When your app needs a long-lived key, the agent first finds where your project
keeps its secrets. It writes the key to that env file with
`graphon api-keys create --write-env`, or pipes it into your secret manager. If
it cannot tell where secrets live, it asks you. The key never appears in the
transcript, and the skills tell the agent never to print, echo, or paste a key.

The skills also tell the agent to use the lowest role that does the job, and
never to delete a bucket, an object, or source data unless you asked for that
exact delete.

## Links

- Documentation: https://docs.beta.graphon.ai/plugin
- Issues: https://github.com/GraphonAI/graphon-plugin/issues
- Security: see `SECURITY.md`

## License

Apache-2.0. See `LICENSE`.
