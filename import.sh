#!/bin/bash

#═══════════════════════════════════╡ BEGIN ╞═══════════════════════════════════
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true


#═════════════════════════════════╡ FUNCTIONS ╞═════════════════════════════════
function __import__ {
   required=$1 ; shift
   declare -a dependencies=( $@ )
   echo "DEPS[required=$required] ${dependencies[@]}"

   declare -a dep_not_met
   declare PROGDIR=$( cd $(dirname "${BASH_SOURCE[0]}") ; pwd )

   for dep in "${dependencies[@]}" ; do
      #───────────────────────────( already sourced )──────────────────────────────
      # If we've already sourced this dependency, its respective __sourced_XX var
      # will be set. Don't re-source. Continue.
      __dep="${dep%.*}"
      __dep_sourcename__="__source_${__dep//[^[:alnum:]]/_}__"
      [[ -n "${!__dep_sourcename__}" ]] && continue

      #───────────────────────────────( source )───────────────────────────────────
      if [[ -e "${LIBDIR}/${dep}" ]] ; then
         if [[ ${#__passdown__[@]} -gt 0 ]] ; then
            source "${LIBDIR}/${dep}" --passdown ${__passdown__[@]}
         else
            source "${LIBDIR}/${dep}"
         fi
      elif [[ $(which ${dep} 2>/dev/null) ]] ; then
         if [[ ${#__passdown__[@]} -gt 0 ]] ; then
            source "$(which ${dep})" --passdown ${__passdown__[@]}
         else
            source "$(which ${dep})"
         fi
      #───────────────────────────( failed sourcing )──────────────────────────────
      else
         $required && dep_not_met+=( "$dep" )
      fi
   done

   #───────────────────────────────( report )───────────────────────────────────
   if [[ ${#dep_not_met} -gt 0 ]] ; then
      # If colors have been sourced, pretty-print output
      if [[ -n $__source_colors__ ]] ; then
         echo -n "[${bl}${__fname__}${rst}] ${brd}ERROR${rst}: "
      # ELse just regular plain-print it. :(
      else
         echo -n "[$__fname__] ERROR: "
      fi

      echo "Failed to source: [${dep_not_met[@]}]"
      echo " + clone from @hre-utils"
      exit 1
   else
      return 0
   fi
}


function .import {
   local lopt
   declare -a dependencies optional passdown

   while [[ $# -gt 0 ]] ; do
      case $1 in
         -d|--dep|--deps)
               shift ; lopt=dependencies ;;

         -o|--optional)
               shift ; lopt=optional ;;

         -p|--passdown)
               shift ; lopt=passdown ;;

         *)    if [[ -z $lopt ]] ; then
                  dependencies+=( $1 )
               else
                  declare -n arr=$lopt
                  arr+=( $1 )
               fi
               
               shift ;;
      esac
   done

   __import__ true  ${dependencies[@]}
   __import__ false ${optional[@]}
}
