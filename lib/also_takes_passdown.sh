#!/bin/bash
# Tests something that also takes passdown arguments

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true

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

   grep -e "^TWO$" <<< "${passdown/,/$'\n'}"
}
