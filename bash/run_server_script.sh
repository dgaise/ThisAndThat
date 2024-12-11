#!/usr/bin/env bash

# configuration
SCRIPT=~/ThisAndThat/perl/processing_script.pl
LOG=/var/logs/little_processing_server.log
RUN_AS_ROOT=yes # 'yes' or 'no'

# run times
HOURS=$(seq -f "%02.0f" 0 23) # every hour from 00 to 23
#MINUTES="40"                  # run at 40th minute
MINUTES="05 55"        # at 5th minute and 55th

# we don't need to change from here down; this code will be the same
# regardless of what script we're running with the server

TIMEZONE=UTC
TODAY=$(date +'%Y-%m-%d')

declare -a TIMES # array to hold run times
for h in $HOURS; do
  for m in $MINUTES; do
    TIMES+=("$h:$m")
  done
done

# get the fully qualified name of the currently running script
SELF="${BASH_SOURCE[0]}"
SELFDIR=$(cd $(dirname $SELF); pwd)
SELFNAME=$(basename "$SELF")
SELF="$SELFDIR/$SELFNAME"

process_pid () {
  ps aux | grep -v grep | grep "$SELF BACKGROUND" | awk '{ print $2 }' | paste -sd "|"
}

# if we're passed the parameter "stop", kill the process running in
# the background and its associated sleep command
if [[ "$1" == "show" ]]; then
  PROCESS_PID=$(process_pid)
  if [[ -z "$PROCESS_PID" ]]; then
    echo "Server not running"
  else
    ps -eo user,pid,ppid,pgid,sid,stat,time,command --forest | awk "NR==1 || /$PROCESS_PID/ { print }" | grep -v awk
  fi
  exit
fi

# if we're passed the parameter "show", show the process and its children
if [[ "$1" == "stop" ]]; then
  PROCESS_PID=$(process_pid)
  PIDS_TO_STOP=$(ps -eo pid,ppid | grep $PROCESS_PID | awk '{ print $1 }')
  for pid in $PIDS_TO_STOP; do
    kill $pid
  done
  exit
fi

# if we're passed the parameter "log", show the log
if [[ "$1" == "log" ]]; then
  less -RX $LOG
  exit
fi

if [[ ! -z "$1" && "$1" != "BACKGROUND" ]]; then
  >&2 echo "Unknown parameter '$1'"
  >&2 echo "Valid parameters are 'show', 'stop', 'log', or no parameter to start"
  exit
fi

# from here on, if we need to run as root, we should be running as root
if [[ "$RUN_AS_ROOT" == "yes" && $UID -ne 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi

# if we were passed no parameters, start THIS script again and
# put it in the background
if [[ -z "$1" ]]; then
  PROCESS_PID=$(process_pid)
  if [[ ! -z "$PROCESS_PID" ]]; then
    >&2 echo "Server is already running on PID $PROCESS_PID"
    >&2 echo "Run '$SELF stop' to stop"
    exit
  fi
  echo Running in background...
  nohup $SELF BACKGROUND >> $LOG 2>> $LOG &
  exit
fi

log () {
  MSG=$1
  [[ ! -z $DEBUG ]] && echo "$(TZ=$TIMEZONE date +'%Y-%m-%d %H:%M:%S-%Z') $MSG"
  echo "$(TZ=$TIMEZONE date +'%Y-%m-%d %H:%M:%S-%Z') $MSG" >> $LOG
}

increment_counter () {
  # increment counter, rolling over once it exceeds maximum value
  counter=$(( ($counter + 1) % ${#TIMES[@]} ))
  if [[ $counter -eq 0 ]]; then
    # the counter has rolled over, increment the day
    TODAY=$(date -d '+1 day' +'%Y-%m-%d')
  fi
}

calculate_sleep_seconds () {
  NEXT_TIME=${TIMES[$counter]}
  target_epoch=$(TZ=$TIMEZONE date -d "$TODAY $NEXT_TIME $TIMEZONE" +'%s')
  current_epoch=$(TZ=$TIMEZONE date +'%s')
  sleep_seconds=$(( $target_epoch - $current_epoch ))
}

find_next_run_time () {
  calculate_sleep_seconds
  while [[ $sleep_seconds -le 0 ]]; do
    log "Run time '$TODAY $NEXT_TIME $TIMEZONE' is in the past..."
    increment_counter
    calculate_sleep_seconds
  done
}

# first, find the next execution time...
counter=0
log "Script starting; locating first run time..."
find_next_run_time

# now loop through the TIMES array, sleep until those times,
# then execute the script and go back to sleep
while true; do
  log "Sleeping until $TODAY $NEXT_TIME $TIMEZONE"
  sleep $sleep_seconds

  log "Running $SCRIPT"
  $SCRIPT >> $LOG 2>> $LOG
  log "$SCRIPT exited"

  # find the next run time; if the script ran so long we overran the
  # next execution time, skip it and find the one after that
  increment_counter
  find_next_run_time
done
