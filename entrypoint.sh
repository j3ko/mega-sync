#!/bin/bash

export MEGA_CMD="${MEGA_CMD:-}"
export MEGA_PATH="${MEGA_PATH:-/}"

# Function to handle termination signals
cleanup() {
  echo "DEBUG: Stopping container..." >&2
  mega-logout
  exit 0
}

# Function to generate a machine ID
generate_machine_id() {
  if [ ! -f /etc/machine-id ]; then
    echo "DEBUG: Generating new machine ID..." >&2
    uuid=$(dd if=/dev/urandom bs=1 count=16 2>/dev/null | sha256sum | head -c 32)
    echo "$uuid" > /etc/machine-id
  fi
}

# Trap termination signals (e.g., SIGTERM, SIGINT)
trap cleanup SIGTERM SIGINT

# Function to create or update the user and group
setup_user() {
  if [ "$PUID" -eq 0 ] && [ "$PGID" -eq 0 ]; then
    echo "DEBUG: Running as root..." >&2
    HOME_DIR="/root"
    return
  fi

  echo "DEBUG: Setting up user with UID: $PUID and GID: $PGID..." >&2

  # Create the group if it doesn't exist
  if ! getent group "$PGID" >/dev/null; then
    groupadd -g "$PGID" megagroup
  fi

  # Create the user if it doesn't exist
  if ! id -u "$PUID" >/dev/null 2>&1; then
    useradd -u "$PUID" -g "$PGID" -m -d /home/megasync megasync
  fi

  # Set permissions for critical directories
  mkdir -p /home/megasync/.megaCmd
  chown -R "$PUID:$PGID" /home/megasync/.megaCmd

  # Set permissions for local paths in MEGA_CMD (for mega-sync commands)
  if [ -n "$MEGA_CMD" ]; then
    echo "DEBUG: Parsing MEGA_CMD for sync paths: $MEGA_CMD" >&2
    IFS=',' read -ra COMMANDS <<< "$MEGA_CMD"
    for cmd in "${COMMANDS[@]}"; do
      # Extract the local path (second argument) if the command is mega-sync
      if [[ "$cmd" =~ ^[[:space:]]*(mega-)?sync[[:space:]]+([^[:space:]]+).* ]]; then
        local_path="${BASH_REMATCH[2]}"
        if [ -n "$local_path" ]; then
          echo "DEBUG: Setting permissions for sync path: $local_path" >&2
          mkdir -p "$local_path"
          chown -R "$PUID:$PGID" "$local_path"
        fi
      fi
    done
  else
    echo "DEBUG: Setting permissions for default sync path: /data" >&2
    mkdir -p /data
    chown -R "$PUID:$PGID" /data
  fi
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
  echo "DEBUG: Logging in to MEGA..." >&2
  if [ -n "$SESSION" ]; then
    gosu "$PUID:$PGID" mega-login "$SESSION"
  elif [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    gosu "$PUID:$PGID" mega-login "$USERNAME" "$PASSWORD"
  else
    echo "ERROR: Either SESSION or both USERNAME and PASSWORD must be set." >&2
    exit 1
  fi
}

# Log in to MEGA
mega_login

# Function to execute multiple MEGA commands
execute_commands() {
  local pids=()
  if [ -n "$MEGA_CMD" ]; then
    echo "DEBUG: Processing MEGA_CMD: $MEGA_CMD" >&2
    IFS=',' read -ra COMMANDS <<< "$MEGA_CMD"
    echo "DEBUG: Split into ${#COMMANDS[@]} commands" >&2
    for cmd in "${COMMANDS[@]}"; do
      # Trim leading/trailing whitespace
      cmd=$(echo "$cmd" | xargs)
      if [ -n "$cmd" ]; then
        # Add mega- prefix if not already provided
        if [[ "$cmd" != mega-* ]]; then
          cmd="mega-$cmd"
        fi
        echo "DEBUG: Executing command: $cmd" >&2
        # Run the command in the background, redirecting stdout to stderr to capture sync messages
        gosu "$PUID:$PGID" env HOME="$HOME_DIR" MEGACMD_CONFIG_DIR="$MEGACMD_CONFIG_DIR" bash -c "$cmd >&2" &
        local pid=$!
        pids+=($pid)
        echo "DEBUG: Command '$cmd' started with PID: $pid" >&2
      else
        echo "DEBUG: Skipping empty command" >&2
      fi
    done
  else
    # Default behavior: sync /data with the specified MEGA_PATH
    echo "DEBUG: No MEGA_CMD provided. Starting default sync for /data -> $MEGA_PATH" >&2
    gosu "$PUID:$PGID" mega-sync /data "$MEGA_PATH" >&2 &
    local pid=$!
    pids+=($pid)
    echo "DEBUG: Default sync started with PID: $pid" >&2
  fi
  # Output only the PIDs, one per line, to stdout
  printf '%s\n' "${pids[@]}"
}

# Execute the commands and capture PIDs
echo "DEBUG: Starting command execution" >&2
pids=($(execute_commands))
echo "DEBUG: Command PIDs: ${pids[*]}" >&2

# Monitor the log file
echo "DEBUG: Monitoring log file: $MEGACMD_CONFIG_DIR/megacmdserver.log" >&2
tail -f "$MEGACMD_CONFIG_DIR/megacmdserver.log" &
TAIL_PID_LOG=$!
echo "DEBUG: Log tail started with PID: $TAIL_PID_LOG" >&2

# Wait for all command PIDs and the log tail process
echo "DEBUG: Waiting for PIDs: ${pids[*]} $TAIL_PID_LOG" >&2
wait "${pids[@]}" "$TAIL_PID_LOG"