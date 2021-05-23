#!/bin/bash
# Better bash `source` function. Pulls either from a globally set $LIBDIR
# variable, else looks for executable file in $PATH.
#
# Currently am specifically passing the --msg's as arguements to each individual
# file's __init__ funct. This could certainly more easily be easier done via a
# global variable, but the long and short of it is... I didn't want to. Feels
# more 'right' to have it be an actual param that's passed down, as it would be
# in a traditional language. There is the potential to which we can more easily
# handle these 'scoped' msgs differently, which would be more difficult with a
# single global variable. But who knows.

#──────────────────────────────────( prereqs )──────────────────────────────────
# Necessary for a bit more introspection:
shopt -s extdebug

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
__file__="${__fname__//[^[:alnum:]]/_}"

declare "__source_${__file__}__"=true

#────────────────────────────────( define self )────────────────────────────────
# Script local global variables. Allows each program to have its own PROGDIR
# wout collisions. Dictionary id dynamically named after this filename, with a
# small & consistent number of transformations:
#  1. The final suffix is stripped
#  2. All non-'word' characters are converted to '_'
declare -A "__${__file__}__"
declare -n self="__${__file__}__"

self=(
   [progdir]=$( cd $(dirname "${BASH_SOURCE[0]}") ; pwd )
   [fname]="$__fname__"
   [verbose]=false
)

#─────────────────────────────────( functions )─────────────────────────────────
function .import {
   declare lopt msg
   declare -a dependencies optional

   # Access global self-dict... need to first re-calculate the transformed name
   # of the file: strip suffix, replace non-word characters.
   local self="$( basename "${BASH_SOURCE[0]%.*}" )"
   local -n self="__${self//[^[:alnum]]/_}__"

   # Argparse...
   while [[ $# -gt 0 ]] ; do
      case $1 in
         -d|--dep|--deps)
               shift ; lopt=dependencies ;;

         -o|--optional)
               shift ; lopt=optional ;;

         -m|--msg)
               shift ; msg="$1" ; shift ;;

         -v|--verbose)
               shift ; self[verbose]=true ;;

         # Append $1 to the last passed flag:
         *)    if [[ -z $lopt ]] ; then
                  dependencies+=( $1 )
               else
                  declare -n arr=$lopt
                  arr+=( "$1" )
               fi

               shift ;;
      esac
   done

   #─────────────────────────────( validation )─────────────────────────────────
   declare -a found_deps=()
   declare -a dep_not_met=()

   # Check if required deps exist:
   for dep in "${dependencies[@]}" ; do
      if [[ -e "${LIBDIR}/${dep}" ]] ; then
         path="${LIBDIR}/${dep}"
         found_deps+=( "$path" )
      elif [[ $(which ${dep} 2>/dev/null) ]] ; then
         path=$(which ${dep} 2>/dev/null)
         found_deps+=( "$path" )
      else
         dep_not_met+=( "$dep" )
      fi
   done

   # Check if required deps exist:
   for dep in "${optional[@]}" ; do
      if [[ -e "${LIBDIR}/${dep}" ]] ; then
         path="${LIBDIR}/${dep}"
         found_deps+=( "$path" )
      elif [[ $(which ${dep} 2>/dev/null) ]] ; then
         path=$(which ${dep} 2>/dev/null)
         found_deps+=( "$path" )
      fi
   done

   # Explode if not met:
   if [[ ${#dep_not_met} -gt 0 ]] ; then
      echo "[${self[fname]}] Failed to source: [${dep_not_met[@]}]" >&2
      return 1
   fi

   #───────────────────────────────( source )───────────────────────────────────
   for path in "${found_deps[@]}" ; do
      #────────────────────────( already sourced )──────────────────────────────
      # If we've already sourced this dependency, its respective __sourced_XX__
      # var will be set. Don't re-source--continue.

      local dep_name=$( basename "$path" )
      local dep_noext="${dep_name%.*}"

      dep_sourcename="__source_${dep_noext//[^[:alnum:]]/_}__"
      [[ -n "${!dep_sourcename}" ]] && continue

      #────────────────────────────( source )───────────────────────────────────
      source "$path"

      # Ensure we're sourcing the __init__ function from the file we've just
      # sourced.
      read fn lineno file < <(declare -F '__init__')
      if [[ "$file" == "$path" ]] ; then
         __init__ "${msg}" ; unset __init__
      fi

      ${self[verbose]} && echo "[${self[fname]}] sourcing: $path"
   done
}
