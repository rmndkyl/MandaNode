#!/bin/bash

# Hide cursor
tput civis

# Clear Line
CL="\e[2K"
# Spinner Characters
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Trap to handle script interruption and cleanup
trap 'tput cnorm; exit' INT TERM

function spinner() {
  local task=$1
  local msg=$2
  while :; do
    jobs %1 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      printf "${CL}✓ ${task} Done\n"
      break
    fi
    for (( i=0; i<${#SPINNER}; i++ )); do
      sleep 0.1
      printf "${CL}${SPINNER:$i:1} ${task} ${msg}\r"
    done
  done
}

msg="${2:-In Progress}"
task="${3:-$1}"

# Execute the task in the background and run the spinner
$1 & spinner "$task" "$msg"

# Show cursor again
tput cnorm

# Usage example:
# ./loader.sh "sleep 5" "..." "Installing Dependencies"