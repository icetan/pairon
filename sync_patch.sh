sync_commit() {
  git add -A "${1-$GIT_WORK_TREE}"
  git commit -m "pairon auto commito"
}
sync_patch() {
  set -x
  #test -e "$CONSUME_FILE" && \
  sync_commit "$1" >/dev/null 2>&1 \
    && { git format-patch --stdout -p HEAD^;echo ___END_OF_MESSAGE___; } >> "$CONSUME_FILE"
}
