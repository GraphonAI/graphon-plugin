#!/bin/sh
# The plugin install contract. It installs the Graphon CLI when the agent's
# machine does not have it, and it prints nothing on stdout or stderr.
#
# AGENT_RULE: this script must stay silent and must not write a shell profile.
# A coding agent runs it at session start and reads stdout as tool output, so
# one echo breaks every session that loads the plugin. The product case
# "a plugin hook can install graphon without prompts and without a change to
# shell profiles" runs this file and asserts both.
#
# The build fills the install origin below from serviceUrls(target).www.
set -u

# A failed install must stay silent and must not fail the session. The agent
# still works: the graphon skill installs the CLI before its first call. curl
# writes to stderr on a bad status, and an agent surfaces stderr, so the
# install attempt swallows both streams.
if ! "$HOME/.local/bin/graphon" --version >/dev/null 2>&1; then
  curl -fsSL 'https://beta.graphon.ai/install.sh' 2>/dev/null | sh -s -- --no-modify-path --quiet 2>/dev/null
fi

# Claude Code reads this file to build the session PATH. Other agents do not
# set it, and the CLI is called by its full path there.
#
# SessionStart fires again on a resume, a compact, and a fork, against the
# same file, so append only once. Without the guard PATH grows by one copy
# each time a long session compacts.
if [ -n "${CLAUDE_ENV_FILE:-}" ] &&
  ! grep -qs '^export PATH="\$HOME/\.local/bin:\$PATH"$' "$CLAUDE_ENV_FILE"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi
