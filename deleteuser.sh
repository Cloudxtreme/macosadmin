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

while getopts ":hm:" OPT; do
    case $OPT in
        h)
            echo "$USAGE"
            exit 0
            ;;
        m)
            if echo ${VALIDMODES[@]} | grep -q -w "$OPTARG"; then
                MODE=$OPTARG
            else
                echo "Invalid home folder mode specified with -$OPT!"
                echo "$USAGE"
                exit 1;
            fi
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

if [[ -z "$1" ]]; then
    echo "No username specified for deletion!"
    exit 1
fi

USERNAME=$1

USEREXISTS=$(dscl . -list /Users | grep -c ^"$1"$)

if (( $USEREXISTS == 0 )); then
    echo "The specified user, $USERNAME, does not exist!"
    exit 1
fi

if [[ "$MODE" == "save" ]]; then
    if [[ ! -e "/Users/Deleted Users" ]]; then
        mkdir -m 770 "/Users/Deleted Users"
    fi
    hdiutil create -format UDZO -srcfolder "/Users/$USERNAME" "/Users/Deleted Users/$USERNAME.dmg"
fi

dscl . -delete "/Users/$USERNAME"

if [[ "$MODE" != "leave" ]]; then
    rm -rf "/Users/$USERNAME"
fi
