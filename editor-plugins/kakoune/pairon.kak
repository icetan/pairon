def -docstring %{autosave-enable: enable autosave for this file buffer} \
autosave-enable %{ %sh{
  [ "${kak_buffile}" ] \
    && printf %s\\n 'hook -group autosave buffer NormalIdle .* %{ %sh{
      [ "${kak_modified}" == "true" ] && echo "exec -save-regs : :w<ret>"
    }}'
}}

def -docstring %{autosave-enable: disable autosave for this file buffer} \
autosave-disable %{
  remove-hooks buffer autosave
}

def -docstring %{pairon-sync: pairon sync this buffer} \
pairon-sync %{ %sh{
  ( pairon sync "${kak_buffile}" 2>&1 ) > /dev/null 2>&1 < /dev/null &
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
         nop %sh{ kill ${pid}; rm -r $(dirname ${output}) }
         remove-hooks buffer fifo
      }
    }"
}}

def -docstring %{pairon-enable: enable pairon sync} \
pairon-enable %{
  hook -group pairon global BufCreate .* %{ %sh{
    [ "${kak_buffile}" ] && pairon path -q "${kak_buffile}" \
      && printf %s\\n 'eval %{
        autosave-enable
        set buffer autoreload yes
        hook -group pairon buffer BufWritePost .* pairon-sync
      }'
  }}
}

def -docstring %{pairon-enable: disable pairon sync} \
pairon-disable %{
  autosave-disable
  set buffer autoreload ask
  remove-hooks buffer pairon
  remove-hooks global pairon
}
