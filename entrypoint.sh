#!/bin/bash

export MEGA_CMD="${MEGA_CMD:-}"
export MEGA_PATH="${MEGA_PATH:-/}"

# Function to handle termination signals
cleanup() {
  echo "Stopping container..."
  mega-logout
  exit 0
}

# Function to generate a machine ID
generate_machine_id() {
  if [ ! -f /etc/machine-id ]; then
    echo "Generating new machine ID..."
    uuid=$(dd if=/dev/urandom bs=1 count=16 2>/dev/null | sha256sum | head -c 32)
    echo "$uuid" > /etc/machine-id
  fi
}

# Trap termination signals (e.g., SIGTERM, SIGINT)
trap cleanup SIGTERM SIGINT

# Function to create or update the user and group
setup_user() {
  if [ "$PUID" -eq 0 ] && [ "$PGID" -eq 0 ]; then
    echo "Running as root..."
    HOME_DIR="/root"
    return
  fi

  echo "Setting up user with UID: $PUID and GID: $PGID..."

  # Create the group if it doesn't exist
  if ! getent group "$PGID" >/dev/null; then
    groupadd -g "$PGID" megagroup
  fi

  # Create the user if it doesn't exist
  if ! id -u "$PUID" >/dev/null 2>&1; then
    useradd -u "$PUID" -g "$PGID" -m -d /home/megasync megasync
  fi

  # Set permissions for critical directories
  mkdir -p /home/megasync/.megaCmd /data
  chown -R "$PUID:$PGID" /home/megasync/.megaCmd /data
  HOME_DIR="/home/megasync"
}

# Set up the user and group
setup_user

# Ensure MEGACMD server logs and config are in the right location
export MEGACMD_CONFIG_DIR="$HOME_DIR/.megaCmd"
export HOME="$HOME_DIR"

# Generate machine ID if not already present
generate_machine_id

# Login function
mega_login() {
  echo "Logging in to MEGA..."
  if [ -n "$SESSION" ]; then
    gosu "$PUID:$PGID" mega-login "$SESSION"
  elif [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    gosu "$PUID:$PGID" mega-login "$USERNAME" "$PASSWORD"
  else
    echo "Error: Either SESSION or both USERNAME and PASSWORD must be set."
    exit 1
  fi
}

# Log in to MEGA
mega_login

# Default behavior: sync /data with the specified MEGA_PATH if no command is provided
if [ -z "$MEGA_CMD" ]; then
  MEGA_CMD="mega-sync /data $MEGA_PATH"
fi

# Add mega- prefix if not already provided and execute the command
if [[ "$MEGA_CMD" != mega-* ]]; then
  MEGA_CMD="mega-$MEGA_CMD"
fi

# Execute the MEGA_CMD
echo "Executing command: $MEGA_CMD"
gosu "$PUID:$PGID" env HOME="$HOME_DIR" MEGACMD_CONFIG_DIR="$MEGACMD_CONFIG_DIR" bash -c "$MEGA_CMD" &

# Monitor the log file
TAIL_PID=$!
tail -f "$MEGACMD_CONFIG_DIR/megacmdserver.log" &
TAIL_PID_LOG=$!

# Wait for termination signal and cleanup
wait $TAIL_PID $TAIL_PID_LOG
