#!/bin/bash
# Better bash `source` function.
# Pulls either from a globally set $LIBDIR variable, else looks for executable
# file in $PATH.

#──────────────────────────────────( prereqs )──────────────────────────────────
# Necessary for a bit more introspection:
shopt -s extdebug

#─────────────────────────────────( source me )─────────────────────────────────
# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf__=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true

#────────────────────────────────( define self )────────────────────────────────
# Script local global variables. Allows each program to have its own PROGDIR
# wout collisions.
declare -A "__${__fname__//[^[:alnum]]/_}__"
declare -n self="__${__fname__//[^[:alnum]]/_}__"

self[progdir]=$( cd $(dirname "${BASH_SOURCE[0]}") ; pwd )
self[libdir]="${self[progdir]}/lib"
self[verbose]=false
self[fname]="$__fname__"

#─────────────────────────────────( functions )─────────────────────────────────
function .import {
   declare lopt passdown
   declare -a dependencies optional

   # Access global self-dict...
   local self="$( basename "${BASH_SOURCE[0]%.*}" )"
   local -n self="__${self//[^[:alnum]]/_}__"

   # Argparse...
   while [[ $# -gt 0 ]] ; do
      case $1 in
         -d|--dep|--deps)
               shift ; lopt=dependencies ;;

         -o|--optional)
               shift ; lopt=optional ;;

         -p|--passdown)
               shift ; passdown="$1" ; shift ;;

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
      source "$path" ${passdown:+--passdown} "${passdown}"
      echo "Sourced: $path ${passdown:+--passdown} ${passdown}"

      # Ensure we're sourcing the __init__ function from the file we've just
      # sourced.
      read fn lineno file < <(declare -F '__init__')
      if [[ "$file" == "$path" ]] ; then
         __init__ ; unset __init__
      fi

      # CURRENT;THINKIES;TODO;
      # This is really close to actually working, but not quite. Maybe each
      # function upon creation populates a uniquely generated dictionary
      # with the args that were passed to it? Then the init function looks
      # at those args? Not sure if I like that approach. Need to sleep on
      # this.

      ${self[verbose]} && echo "[${self[fname]}] sourcing: $path"
   done
}
