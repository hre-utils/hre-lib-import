#!/bin/bash

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true

#═════════════════════════════════╡ FUNCTIONS ╞═════════════════════════════════
function __import__ {
   [[ $1 == --required ]] && {
      local required=true ; shift
   }

   local fname="$__fname__"
   # Need to use a local fname here, as the globally scoped __fname__ will be
   # overwritten by each additional script we source. Need to keep consistent
   # within this scope for accurate error reporting.

   declare -a dependencies=( "$@" )
   declare -a dep_not_met

   declare PROGDIR=$( cd $(dirname "${BASH_SOURCE[0]}") ; pwd )
   declare LIBDIR="${PROGDIR}/lib"

   for dep in "${dependencies[@]}" ; do
      #────────────────────────( already sourced )──────────────────────────────
      # If we've already sourced this dependency, its respective __sourced_XX__
      # var will be set. Don't re-source--continue.

      __dep_noext__="${dep%.*}"
      __dep_sourcename__="__source_${__dep_noext__//[^[:alnum:]]/_}__"
      [[ -n "${!__dep_sourcename__}" ]] && continue

      #────────────────────────────( source )───────────────────────────────────
      # Attempt to source in priority of:
      if [[ -e "${LIBDIR}/${dep}" ]] ; then           # 1) ./lib/$dep
         local path="${LIBDIR}/${dep}"
      elif [[ $(which ${dep} 2>/dev/null) ]] ; then   # 2) which $dep (in $PATH)
         local path=$(which ${dep})
      else
         $required && dep_not_met+=( "$dep" )         # else: Not installed :(
         $__verbose__ && {
            echo "[$fname] not sourced: ${dep}, required: $required"
         }
         continue
      fi

      source "$path" ${__passdown__[@]:+--passdown} "${__passdown__[@]}"

      $__verbose__ && {
         echo -n "[$fname] sourcing: "
         echo "$path ${__passdown__[@]:+--passdown} ${__passdown__[@]}"
      }
   done

   #───────────────────────────────( report )───────────────────────────────────
   if [[ ${#dep_not_met} -gt 0 ]] ; then
      echo -n "[${bl}${fname}${rst}] ${brd}ERROR${rst}: " >&2
      echo "Failed to source: [${dep_not_met[@]}]" >&2
      exit 1
   else
      return 0
   fi
}


function .import {
   local lopt
   declare -a dependencies optional
   declare -ag __passdown__

   while [[ $# -gt 0 ]] ; do
      case $1 in
         -d|--dep|--deps)
               shift ; lopt=dependencies ;;

         -o|--optional)
               shift ; lopt=optional ;;

         -p|--passdown)
               shift ; lopt=__passdown__ ;;

         -v|--verbose)
               shift ; __verbose__=true ;;

         # Append $1 to the last passed flag:
         *)    if [[ -z $lopt ]] ; then
                  dependencies+=( $1 )
               else
                  declare -n arr=$lopt
                  arr+=( $1 )
               fi

               shift ;;
      esac
   done

   __import__ --required  "${dependencies[@]}"
   __import__ "${optional[@]}"
}
