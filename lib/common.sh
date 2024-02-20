#!/bin/sh
exec 0<&-

export TZ=UTC
export LC_ALL=C
# shellcheck disable=SC2034
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
INSTALL_DIR="${SCRIPT_PATH%/*/*}"
# shellcheck disable=SC2034
LIBEXEC_DIR="$INSTALL_DIR/libexec"
LIB_DIR="$INSTALL_DIR/lib"
# shellcheck disable=SC2034
TEMPLATE_DIR="$INSTALL_DIR/template"
PARION_SHELL="${PAIRON_SHELL:-sh}"

export GIT_CONFIG_NOSYSTEM=1
unset XDG_CONFIG_HOME
unset HOME

# shellcheck source=lib/sync_patch.sh
. "$LIB_DIR/sync_patch.sh"

alias linebuf='stdbuf -eL -oL'

rtrav() {
  if test -e "$2/$1"; then
    printf %s "$2"
  else
    { test "$2" != / && rtrav "$1" "$(dirname "$2")"; }
  fi
}

info() { echo "Info: $*" >&2; }
warn() { echo "Warning: $*" >&2; }
die() {
  test -z "$*" || { echo "Error: $*\n" >&2; exit 1; }
  exit
}
usage() {
  test -z "$USAGE" || echo "$USAGE\n\nVersion: ${PAIRON_VERSION:-Unknown}\n" >&2
  die "$@"
}

stop() {
  test -n "$1" && echo "$1" >&2
  exit 0
}
initrepo() {
  (cd "$1" || exit 1
    cp $TEMPLATE_DIR/ignore .paironignore
    touch .pairon/produce
    git config -f .pairon/config core.sharedRepository group
    git config -f .pairon/config core.excludesFile .paironignore
    git config -f .pairon/config user.email "$(whoami)@$(hostname 2>/dev/null || cat /proc/sys/kernel/hostname)"
    git config -f .pairon/config user.name "$(whoami)"
    git config -f .pairon/config receive.denyCurrentBranch ignore
    git config -f .pairon/config --unset core.worktree || true
    git config -f .pairon/config pull.ff only
  )
}
setrepo() {
  local worktree=$(pairon_path "$1") || die "Not a pairon repo"
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
    warn "Couldn't resolve merge, doing a hard reset"
    git merge --abort || true
    git reset --hard origin/master
  }
}
sync_push() {
  RETRY_COUNT="$((RETRY_COUNT + 1))"
  test "$RETRY_COUNT" -le "$MAX_RETRY" || die "Reached max pull retry count"
  git push || {
    sync_merge || true
    info "Retrying $RETRY_COUNT" >&2
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
  local path="$1"
  local exclude="$2"
  if command -v inotifywait >/dev/null; then
    info "Using inotify"
    inotifywait -mr \
       --exclude "$exclude" \
       -e modify,create,delete,move "$path" \
       --timefmt '%s' --format "%T '%w%f'" \
    | linebuf uniq \
    | linebuf sed 's/[0-9]* //'
  else
    info "Using fswatch"
    fswatch -r --event Created --event Updated --event Removed \
       --event Renamed --event MovedFrom --event MovedTo \
       -f '%s' -t --format "'%p'" \
       -e "$(echo "$exclude" | sed 's/|/\\|/g')" "$path" \
    | linebuf uniq \
    | linebuf sed 's/[0-9]* //'
  fi
}
