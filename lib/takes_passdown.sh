#!/bin/bash
# Tests something that takes passdown arguments

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
__file__="${__fname__//[^[:alnum:]]/_}"

declare "__source_${__file__}__"=true

#────────────────────────────────( define self )────────────────────────────────
# Global self-dict. Allows us to 'scope' global variables only to this file.
declare -A "__${__file__}__"
declare -n self="__${__file__}__"

self=(
   [progdir]=$( cd $(dirname "${BASH_SOURCE[0]}") ; pwd )
   [fname]="$__fname__"
)

#─────────────────────────────────( functions )─────────────────────────────────
function foo {
   # Access global self-dict
   declare self="$( basename "${BASH_SOURCE[0]%.*}" )"
   declare -n self="__${self//[^[:alnum]]/_}__"

   echo "self ${self[verbose]}"
}

function __init__ {
   #────────────────────────────────( setup )───────────────────────────────────
   local msg="$1"

   # Access global self-dict... need to first re-calculate the transformed name
   # of the file: strip suffix, replace non-word characters.
   local self="$( basename "${BASH_SOURCE[0]%.*}" )"
   local -n self="__${self//[^[:alnum]]/_}__"

   if [[ $(grep -e "^ONE$" <<< "${msg//,/$'\n'}") ]] ; then
      echo "I am in ${self[progdir]} @ ${self[fname]}"
   fi

   .import also_takes_passdown.sh --msg "$msg"
}
