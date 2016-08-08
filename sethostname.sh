#!/bin/bash

USAGE='Usage: sethostname -c
       sethostname <name>

options:
  -c Use the current ComputerName to set the other values (see below)
  -h Display this usage message

This script uses the scutil utility to set the ComputerName, LocalHostName,
and HostName values. If the -c option is used, any arguments are ignored and
the current ComputerName is used to set LocalHostName and HostName. Otherwise,
it is expected that <name> is the desired ComputerName and a valid hostname
will be generated from that ComputerName. A valid host name can only have
letters, numbers, and hyphens.

For an overview of the differences between the three names, plase
reference this site: http://ilostmynotes.blogspot.com/2012/03/computername-vs-localhostname-vs.html'

COMPUTERNAME=""

while getopts ":ch" opt; do
    case $opt in
        c)
            COMPUTERNAME="$(scutil --get ComputerName)"
            ;;
        h)
            echo "$USAGE"
            exit 0
            ;;
        \?)
            echo "The -$OPTARG option is not valid." >&2
            echo "$USAGE"
            exit 1
            ;;
        :)
            echo "The -$OPTARG option requires an argument." >&2
            echo "$USAGE"
            exit 1
            ;;
        *)
            echo "An unknown error occured while processing the options!" >&2
            exit 1;
            ;;
    esac
done

shift $((OPTIND-1))

if [[ -z "$COMPUTERNAME" ]]; then
    if [[ -n "$1" ]]; then
        COMPUTERNAME=$1
    else
        echo "No computer name was specified!"
        exit 1
    fi
fi

HOSTNAME=$(echo "$COMPUTERNAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | \
    tr -c -d '[:alpha:][:digit:]-')

scutil --set ComputerName "$COMPUTERNAME"
scutil --set LocalHostName "$HOSTNAME"
scutil --set HostName "$HOSTNAME"
