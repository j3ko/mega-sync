#!/bin/bash

# Check if mega-whoami command returns a logged-in status
if gosu "$PUID:$PGID" mega-whoami >/dev/null 2>&1; then
  echo "Mega-cmd is connected."
  exit 0
else
  echo "Mega-cmd is not connected."
  exit 1
fi
