#!/bin/sh
exec 0<&-

export SCRIPT_NAME
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

export GIT_CONFIG_NOSYSTEM=1
unset XDG_CONFIG_HOME
unset HOME

# shellcheck source=sync_patch.sh
. "$SCRIPT_DIR/sync_patch.sh"

alias linebuf='stdbuf -eL -oL'
rtrav() {
  if test -e "$2/$1"; then
    printf %s "$2"
  else
    { test "$2" != / && rtrav "$1" "$(dirname "$2")"; }
  fi
}
info() { echo "INFO: $*" >&2; }
warn() { echo "WARNING: $*" >&2; }
die() {
  test -n "$1" && echo "Error: $1" >&2
  exit 1
}
stop() {
  test -n "$1" && echo "$1" >&2
  exit 0
}
initrepo() {
  (cd "$1" || exit 1
    touch .pairon/produce
    git config -f .pairon/config core.sharedRepository group
    git config -f .pairon/config core.excludesfile .pairon/ignore
    git config -f .pairon/config user.email "$(whoami)@$(hostname)"
    git config -f .pairon/config user.name "$(whoami)"
    git config -f .pairon/config receive.denyCurrentBranch ignore
    git config -f .pairon/config --unset core.worktree
  )
}
setrepo() {
  worktree=$(pairon_path "$1") || die "Not a pairon repo"
  export GIT_WORK_TREE="$worktree"
  export GIT_DIR="$worktree/.pairon"
  export CONSUME_FILE="$worktree/.pairon/consume"
}
pairon_path () {
  rtrav .pairon "$({ cd "${1:-.}" || cd "$(dirname "${1:-.}")"; } >/dev/null 2>&1 && pwd)"
}

# SYNC
MAX_RETRY=20
sync_merge() {
  git pull --commit -s recursive -X ours || {
    echo "WARNING: Couldn't resolve merge, doing a hard reset" >&2
    git merge --abort || true
    git reset --hard origin/master
  }
}
sync_push() {
  RETRY_COUNT="$((RETRY_COUNT + 1))"
  test "$RETRY_COUNT" -le "$MAX_RETRY" || die "Reached max pull retry count"
  git push || {
    sync_merge || true
    echo "INFO: Retrying $RETRY_COUNT" >&2
    sync_push
  }
}
sync_force() {
  RETRY_COUNT=0
  sync_commit "$1" || true
  sync_merge
  sync_push
}

fsw() {
  path="$1"
  exclude="$2"
  if command -v inotifywait; then
    info "Using inotify"
    inotifywait -mr --exclude "$exclude" \
       -e modify,create,delete,move "$path" \
       --timefmt '%s' --format "%T '%w%f'" \
    | linebuf uniq \
    | linebuf sed 's/[0-9]* //'
  else
    info "Using fswatch"
    fswatch -r --event Created --event Updated --event Removed \
       --event Renamed \ --event MovedFrom --event MovedTo \
       -f '%s' -t --format "'%p'" \
       -e "$(echo "$exclude" | sed 's/|/\\|/g')" "$path" \
    | linebuf uniq \
    | linebuf sed 's/[0-9]* //'
  fi
}
