#!/bin/bash

USAGE='Usage: deleteuser [options...] <username>

option:
  -m Specify what to do with home folder (see below)
  -h Display this usage message

  There are three possible methods of dealing with the home folder of
  the speficied user. The valid arguments to the -m flag are:

    save   - (default) Save the home folder to a disk image in the
             /Users/Deleted\ Users folder before removing it from /Users.
    leave  - Leave the home folder unchanged
    remove - Remove the home folder

  If you do not specify one of the above methods, the save method is
  assumed.'

VALIDMODES=("save" "leave" "remove")
MODE="save"

while getopts ":hm:" opt; do
    case $opt in
        h)
            echo "$USAGE"
            exit 0
            ;;
        m)
            if echo ${VALIDMODES[@]} | grep -q -w "$OPTARG"; then
                MODE=$OPTARG
            else
                echo "Invalid home folder mode specified with -m!"
                echo "$USAGE"
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        *)
            echo "Unknown error while processing options"
            exit 1;
            ;;
    esac
done

shift $((OPTIND-1))

USERNAME=$1

USEREXISTS=$(dscl . -list /Users | grep -c ^$1$)

#dscl . -delete /Users/$1
#rm -rf /Users/$USERNAME
