#!/bin/sh

if [ -z "$GOPATH" ]; then
    echo GOPATH environment variable not set
    exit
fi

if command -v cygpath.exe > /dev/null 2>&1; then
    GOPATH="$(cygpath.exe "$GOPATH")"
fi

if [ ! -e "$GOPATH/bin/2goarray" ]; then
    echo "Installing 2goarray..."
    if ! go install github.com/cratonica/2goarray; then
        echo Failure executing go install github.com/cratonica/2goarray
        exit
    fi
fi

if [ -z "$1" ]; then
    echo Please specify a PNG file
    exit
fi

if [ ! -f "$1" ]; then
    echo "$1 is not a valid file"
    exit
fi    

OUTPUT=iconunix.go
echo "Generating $OUTPUT"
echo "//+build linux darwin" > $OUTPUT
echo >> $OUTPUT
if ! "$GOPATH/bin/2goarray" Data icon >> $OUTPUT < "$1"; then
    echo Failure generating $OUTPUT
    exit
fi
echo Finished
