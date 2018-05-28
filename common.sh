rtrav() {
  test -e $2/$1 && printf %s "$2" || { test $2 != / && rtrav $1 `dirname $2`; }
}
info() { echo >&2 INFO: $@; }
warn() { echo >&2 WARNING: $@; }
die() {
  [ -n "$1" ] && echo >&2 "Error: $1"
  exit 1
}
stop() {
  [ -n "$1" ] && echo >&2 "$1"
  exit 0
}
initrepo() {
  (cd "$1"
    echo .pairon/ > .pairon/ignore
    touch .pairon/produce
    touch .pairon/consume
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
  rtrav .pairon "$(cd "${1-.}" &>/dev/null || cd "$(dirname "${1-.}")";pwd)"
}

# SYNC
MAX_RETRY=20
sync_commit() {
  git add -A "${1-$GIT_WORK_TREE}" &>/dev/null
  git commit -m "pairon auto commito" &>/dev/null
}
sync_patch() {
  set -x
  sync_commit "$1" \
    && { git format-patch --stdout -p HEAD^;echo -en '\0'; } >> "$CONSUME_FILE"
}
sync_merge() {
  git pull --commit -s recursive -X ours || {
    echo >&2 "WARNING: Couldn't resolve merge, doing a hard reset"
    git merge --abort || true
    git reset --hard origin/master
  }
}
sync_push() {
  ((RETRY_COUNT++<MAX_RETRY)) || die "Reached max pull retry count"
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

exec 0<&-

SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(cd `dirname $0`;pwd)"

export PATH="$PATH:$SCRIPT_DIR"
export GIT_CONFIG_NOSYSTEM=1
unset XDG_CONFIG_HOME
unset HOME
