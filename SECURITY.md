# Security

## Reporting a problem

Email security@graphon.ai. Do not open a public issue for a vulnerability.
We answer within two working days.

## What this plugin holds

The plugin is configuration, documentation, and one shell script. It carries
no credential and no binary.

- The MCP configuration names one fixed `https` URL. It sends no key.
- The session start hook installs the Graphon CLI from the official install
  script when the CLI is missing. The script verifies a SHA-256 for every file
  it downloads, and the CLI verifies an Ed25519 signature on every update.
- The skills instruct the agent never to print or paste an API key, and to
  write a key only into a git-ignored env file through the CLI.

## How the agent gets access

The agent signs in with OAuth. You approve the connection on a Graphon consent
page, and the grant is limited to the role you approve. Revoke it at any time
in Settings, under Security. Revoking stops the agent's access tokens at once.
