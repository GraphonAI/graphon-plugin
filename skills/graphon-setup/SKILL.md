---
name: graphon-setup
description: Use when the user asks to set up Graphon in a project or connect a project to Graphon, or when another Graphon skill finds no login and no API key. Signs in, picks a workspace, and puts an app API key where the project keeps its secrets, without the key reaching the transcript.
license: Apache-2.0
compatibility: all
metadata:
  product: Graphon
---

# Set up Graphon in a project

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

Do these steps in order. Stop at the first failure and load
`graphon-troubleshoot`.

## 1. Find the CLI

Run `graphon --version`. If that fails, use `~/.local/bin/graphon` for every
command below. If that also fails, run the install **once**:

```bash
curl -fsSL https://beta.graphon.ai/install.sh | sh -s -- --no-modify-path --quiet
```

Check `~/.local/bin/graphon --version` again. If it still fails, **stop**.
Report the install output and tell the user Graphon setup needs the CLI. Do
not look for another installer, another binary, or a source checkout.

## 2. Sign in

```bash
graphon whoami
```

If it reports no login, run `graphon login`. It opens a browser. Tell the user
to approve the sign-in, then wait for the command to finish. Do not try to read
or type their password.

If `graphon whoami` still fails after that, **stop** and ask the user to sign
in themselves. Do not open, read, or decode anything under
`~/.config/graphon/`. Do not change permissions there. Those files hold a live
access token, and diagnosing them is not part of setting up a project.

`whoami` prints the account the **CLI** is signed in as. That account can
differ from the one the MCP server uses: they authenticate separately. Say
which account you are about to act as, in one line, before step 5 creates a
key. A key made under the wrong account lands in a workspace the user cannot
see, and nothing else in this flow would tell them.

## 3. Pick the workspace

```bash
graphon workspaces list
```

If the user has one workspace, use it. If they have several, show the list and
ask which one. Then:

```bash
graphon workspaces use <workspace-id>
```

The CLI saves this choice. `graphon workspaces get` prints it later, so no
file in the project needs to hold the workspace ID.

If the list is empty, **stop**. Say: "The account `<email>` has no Graphon
workspace. Create one, or sign in as the account that owns the workspace you
want." An empty list usually means the CLI is signed in as a different account
from the one the user had in mind. Do not create a workspace for them.

Before step 5, state the account and the workspace together, so a mismatch is
visible while it is still cheap to fix:

> Creating an editor key for `<email>` in workspace `<name>`.

## 4. Choose the role

Pick the lowest role the app needs, and say why in one line:

- The app only reads files: `viewer`.
- The app uploads or deletes files: `editor`.
- Do not create an `admin` key for an app.

## 5. Put the key where the app keeps its secrets

The app reads one secret, `GRAPHON_API_KEY`. Hosts and the workspace ID go in
the app's code, so they are not part of this step. The bucket name is not a
secret either. `graphon-app-storage` puts it next to the key.

Find how this project handles secrets before you create the key:

- An env file that the app loads: `.env.local`, `.env`, `.dev.vars`, or a file
  that dotenv or the framework reads.
- A secret manager: `doppler.yaml`, `op://` references, `.infisical.json`, or
  calls to AWS Secrets Manager or Parameter Store.
- The names of other secrets, for example `STRIPE_SECRET_KEY`. Match them.

| You found | Do this |
| --- | --- |
| An env file that git ignores | Write the key there with `--write-env`. |
| A secret manager whose CLI reads a value from stdin | Pipe the key into it. The key passes through the pipe, never the output. |
| Anything else, or you are not sure | Stop. Ask the user where the app keeps its secrets. |

Never create an env file that the project does not use.

For an env file:

```bash
graphon api-keys create --name "<project> <environment>" --role editor --write-env <file>
```

The command writes `GRAPHON_API_KEY` into that file and prints no key. It
replaces an old `GRAPHON_API_KEY` line and keeps every other line. It refuses
a file that git tracks, and it adds the file to `.gitignore` when git does not
already ignore it.

For a secret manager, `graphon api-keys create` without `--write-env` prints
only the key and a newline on stdout, so a pipe carries it. Remove the newline
with `tr`, because some stores keep stdin byte for byte, and a key that ends in
a newline fails every request:

```bash
graphon api-keys create --name "<project> <environment>" --role editor | tr -d '\n' | <command that stores GRAPHON_API_KEY from stdin>
```

Use only a store command that reads the value from stdin and does not print
it. If you do not know one for this manager, stop and ask the user.

**Do not** read the file or the stored secret back, `cat` it, or echo any
value from it.

## 6. Check the ignore rule

Only for an env file:

```bash
git check-ignore -v <file>
```

If the file is not ignored and the command printed no rule, add it to
`.gitignore` yourself and tell the user.

## 7. Confirm

```bash
graphon whoami
graphon buckets list
```

Report the workspace name, the key name, the role, and where the key went.
Do not report the key.

## Next

- The app needs storage code: load `graphon-app-storage`.
- The project needs a bucket: load `graphon-storage`.
- Existing data must move in: load `graphon-migrate`.
