#!/bin/bash

source import.sh

LIBDIR='./lib'

declare -a params=(
   #--verbose
   --deps
         takes_passdown.sh
   --optional
         doesnt-exist.sh
   --passdown
         ONE,TWO,THREE
)

.import "${params[@]}"
