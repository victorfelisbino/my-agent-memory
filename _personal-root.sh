#!/usr/bin/env bash
# Source this from any bash script that reads/writes personal memory data:
#   source "$REPO_ROOT/_personal-root.sh"
#   PERSONAL_ROOT="$(get_personal_root "$REPO_ROOT")"
#
# Resolution order:
#   1. $AGENT_MEMORY_PERSONAL (if set and the path exists)
#   2. Sibling directory of the framework repo named 'my-agent-memory-personal'
#   3. The framework repo itself (legacy fallback)
get_personal_root() {
    local framework_root="$1"
    if [ -n "${AGENT_MEMORY_PERSONAL:-}" ] && [ -d "$AGENT_MEMORY_PERSONAL" ]; then
        (cd "$AGENT_MEMORY_PERSONAL" && pwd)
        return
    fi
    local parent
    parent="$(cd "$(dirname "$framework_root")" 2>/dev/null && pwd || true)"
    if [ -n "$parent" ] && [ -d "$parent/my-agent-memory-personal" ]; then
        (cd "$parent/my-agent-memory-personal" && pwd)
        return
    fi
    echo "$framework_root"
}
