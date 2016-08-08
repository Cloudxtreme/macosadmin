#!/bin/bash

# Adapted from http://wiki.freegeek.org/index.php/Mac_OSX_adduser_script

USAGE='Usage: createuser [options..] <Full Name> <Password>

options:
  -a Make this user an admin user
  -h Display this usage message
  -u Set the username (shortname) explicitly
  -v Verbose mode, otherwise thise script is silent'

# Verbose mode toggle
_VERBOSE=0

function log () {
    if [[ $_VERBOSE -eq 1 ]]; then
        echo "$@"
    fi
}

# For a Standard user, we'll set the PrimaryGroupID to 20 and the add that
# user to the staff and _lpadmin groups. If the -a option is specified for
# an Admin user, we'll change these values.
PRIMARYID=20
OTHERGROUPS="staff _lpadmin"

# USERNAME is the only optional argument. If it's not specified, we'll
# follow the default behavior: lowercase of the fullname without spaces.
USERNAME=

while getopts ":ahu:v" opt; do
    case $opt in
        a)
            # Settings for an Admin user
            PRIMARYID=80
            OTHERGROUPS="admin _lpadmin _appserveradm _appserverusr"
            ;;
        h)
            echo "$USAGE"
            exit 0
            ;;
        u)
            USERNAME=$OPTARG
            ;;
        v)
            _VERBOSE=1
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

if [ $# -lt  2 ]; then
    echo "Not enough arguments received!"
    echo "$USAGE"
    exit 1
fi

FULLNAME=$1
PASSWORD=$2

# If the USERNAME was not set explicitly, create the default
if [ ! $USERNAME ]; then
    USERNAME=$(echo "$FULLNAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
fi

# Find the next available user ID
LASTID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
USERID=$((LASTID + 1))

# Create the account with the dscl utility
dscl . -create /Users/$USERNAME
dscl . -create /Users/$USERNAME UserShell /bin/bash
dscl . -create /Users/$USERNAME RealName "$FULLNAME"
dscl . -create /Users/$USERNAME UniqueID "$USERID"
dscl . -create /Users/$USERNAME PrimaryGroupID $PRIMARYID
dscl . -create /Users/$USERNAME NFSHomeDirectory /Users/$USERNAME
dscl . -passwd /Users/$USERNAME $PASSWORD

# Add the user to the remaining groups
for GROUP in $OTHERGROUPS ; do
    dseditgroup -o edit -t user -a $USERNAME $GROUP
done

# Create the user's home directory
# shell-init: error retrieving current directory: getcwd: cannot access parent directories: Permission denied
createhomedir -c -u $USERNAME  2>&1 | grep -v "shell-init"
