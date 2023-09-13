def -docstring %{pairon-autosave-enable: enable autosave for this file buffer} \
pairon-autosave-enable %{ eval %sh{
  test -n "${kak_buffile}" \
    && printf %s\\n 'hook -group pairon-autosave buffer NormalIdle .* %{ eval %sh{
      test "${kak_modified}" = "true" && echo "exec -save-regs : :w<ret>"
    }}'
}}

def -docstring %{pairon-autosave-enable: disable autosave for this file buffer} \
pairon-autosave-disable %{
  remove-hooks buffer pairon-autosave
}

def -docstring %{pairon-sync: pairon sync this buffer} \
pairon-sync %{ %sh{
  ( pairon sync -f "${kak_buffile}" 2>&1 ) > /dev/null 2>&1 < /dev/null &
}}

def -docstring %{pairon-listen: start a pairon listener in current directory} \
pairon-listen %{ eval %sh{
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

decl -docstring "list of pairon buffers" \
    str-list pairon_buflist

def -docstring %{pairon-enable: enable pairon sync} \
pairon-enable %{ eval %sh{
    test -n "${kak_buffile}" && pairon path -q "${kak_buffile}" \
      && printf %s\\n '
        set-option -add global pairon_buflist %val{buffile}
        pairon-autosave-enable
        set buffer autoreload yes
      '
}}

def -docstring %{pairon-global-enable: enable pairon sync} \
pairon-global-enable %{
  eval -buffer %sh{ echo "${kak_opt_pairon_buflist}" | sed "s/'//g;s/ /,/g" } %{
    pairon-enable
  }
  hook -group pairon global BufCreate .* pairon-enable
}

def -docstring %{pairon-disable: disable pairon sync} \
pairon-disable %{
  remove-hooks global pairon
  eval -buffer %sh{ echo "${kak_opt_pairon_buflist}" | sed "s/'//g;s/ /,/g" } %{
    pairon-autosave-disable
    set-option buffer autoreload ask
  }
  set-option global pairon_buflist ""
}
