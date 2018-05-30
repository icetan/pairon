exec 0<&-

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(dirname $(realpath "$0"))"

export GIT_CONFIG_NOSYSTEM=1
unset XDG_CONFIG_HOME
unset HOME

. "$SCRIPT_DIR/sync_patch.sh"

rtrav() {
  test -e $2/$1 && printf %s "$2" || { test $2 != / && rtrav $1 `dirname $2`; }
}
info() { echo >&2 INFO: $@; }
warn() { echo >&2 WARNING: $@; }
die() {
  test -n "$1" && echo >&2 "Error: $1"
  exit 1
}
stop() {
  test -n "$1" && echo >&2 "$1"
  exit 0
}
initrepo() {
  (cd "$1"
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
  worktree=`pairon_path "$1"` || die "Not a pairon repo"
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
    echo >&2 "WARNING: Couldn't resolve merge, doing a hard reset"
    git merge --abort || true
    git reset --hard origin/master
  }
}
sync_push() {
  RETRY_COUNT=`expr $RETRY_COUNT + 1`
  test $RETRY_COUNT -le $MAX_RETRY || die "Reached max pull retry count"
  git push || {
    sync_merge || true
    echo >&2 "INFO: Retrying $RETRY_COUNT"
    sync_push
  }
}
sync_force() {
  RETRY_COUNT=0
  sync_commit "$1" || true
  sync_merge
  sync_push
}
