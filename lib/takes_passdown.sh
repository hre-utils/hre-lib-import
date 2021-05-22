#!/bin/bash
# Tests something that takes passdown arguments

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true

#────────────────────────────────( define self )────────────────────────────────
# Global self-dict. Allows us to 'scope' global variables only to this file.
declare -A "__${__fname__//[^[:alnum]]/_}__"

#─────────────────────────────────( functions )─────────────────────────────────
function foo {
   # Access global self-dict
   declare self="$( basename "${BASH_SOURCE[0]%.*}" )"
   declare -n self="__${self//[^[:alnum]]/_}__"

   echo "self ${self[verbose]}"
}


function __init__ {
   while [[ $# -gt 0 ]] ; do
      case $1 in
         --passdown)
            shift ;
            passdown="$1" ; shift ;;

         *)
            shift ;;
      esac
   done

   grep -e "^ONE$" <<< "${passdown/,/$'\n'}"
   .import also_takes_passdown.sh --passdown "$passdown"
}
