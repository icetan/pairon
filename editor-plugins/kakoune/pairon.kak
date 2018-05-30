def -docstring %{autosave-enable: enable autosave for this file buffer} \
autosave-enable %{ %sh{
  test -n "${kak_buffile}" \
    && printf %s\\n 'hook -group autosave buffer NormalIdle .* %{ %sh{
      test "${kak_modified}" = "true" && echo "exec -save-regs : :w<ret>"
    }}'
}}

def -docstring %{autosave-enable: disable autosave for this file buffer} \
autosave-disable %{
  remove-hooks buffer autosave
}

def -docstring %{pairon-sync: pairon sync this buffer} \
pairon-sync %{ %sh{
  ( pairon sync -f "${kak_buffile}" 2>&1 ) > /dev/null 2>&1 < /dev/null &
}}

decl -docstring "name of the client in which utilities display information" \
    str toolsclient
def -docstring %{pairon-listen: start a pairon listener in current directory} \
pairon-listen %{ %sh{
    output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-pairon.XXXXXXXX)/fifo
    mkfifo ${output}
    ( pairon listen > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null &
    pid=$!

    printf %s\\n "eval -try-client '$kak_opt_toolsclient' %{
      echo -debug ${pid}
      edit! -fifo ${output} *pairon*
      set buffer filetype log
      hook -group fifo buffer BufCloseFifo .* %{
         nop %sh{ rm -rf $(dirname ${output}); kill ${pid}; }
         remove-hooks buffer fifo
      }
    }"
}}

def -docstring %{pairon-enable: enable pairon sync} \
pairon-enable %{
  hook -group pairon global BufCreate .* %{ %sh{
    test -n "${kak_buffile}" && pairon path -q "${kak_buffile}" \
      && printf %s\\n 'eval %{
        autosave-enable
        set buffer autoreload yes
      }'
  }}
}

def -docstring %{pairon-enable: disable pairon sync} \
pairon-disable %{
  autosave-disable
  set buffer autoreload ask
  remove-hooks global pairon
}
