# mega-sync
Dockerized [Mega](https://mega.nz) sync utility built on [MEGAcmd](https://mega.io/cmd).

## Default Sync
Run the container with your MEGA account credentials to sync a local directory to the root of your MEGA account:

```bash
docker run --name=mega-sync \
  -e USERNAME="your-mega-email@example.com" \
  -e PASSWORD="your-mega-password" \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/host:/data \
  j3ko/mega-sync:latest
```

This will continuously sync `/path/to/host` (mounted as `/data` in the container) to the root of your MEGA account (`/`).

## Sync with Specific MEGA Path
To sync a local directory to a specific path in your MEGA account, use the `MEGA_PATH` environment variable:

```bash
docker run --name=mega-sync \
  -e USERNAME="your-mega-email@example.com" \
  -e PASSWORD="your-mega-password" \
  -e PUID=1000 \
  -e PGID=1000 \
  -e MEGA_PATH=/path/in/mega \
  -v /path/to/host:/data \
  j3ko/mega-sync:latest
```

This will sync `/path/to/host` to `/path/in/mega` in your MEGA account. Ensure remote MEGA path `/path/in/mega` exists before starting the sync.

## Multiple Sync Commands
To sync multiple local directories to different MEGA paths, use the `MEGA_CMD` environment variable with comma-separated `sync` commands:

```bash
docker run --name=mega-sync \
  -e USERNAME="your-mega-email@example.com" \
  -e PASSWORD="your-mega-password" \
  -e PUID=1000 \
  -e PGID=1000 \
  -e MEGA_CMD="sync /data/data1 /remote1,sync /data/data2 /remote2" \
  -v /path/to/host1:/data/data1 \
  -v /path/to/host2:/data/data2 \
  j3ko/mega-sync:latest
```

This will:
- Sync `/path/to/host1` (mounted as `/data/data1`) to `/remote1` in your MEGA account.
- Sync `/path/to/host2` (mounted as `/data/data2`) to `/remote2` in your MEGA account.

## Docker Compose Example
Here’s an example Docker Compose configuration for multiple syncs:

```yaml
version: '3.8'
services:
  mega-sync:
    image: j3ko/mega-sync:latest
    environment:
      USERNAME: your-mega-email@example.com
      PASSWORD: your-mega-password
      PUID: 1000
      PGID: 1000
      MEGA_CMD: sync /data/data1 /remote1,sync /data/data2 /remote2
    volumes:
      - /path/to/host1:/data/data1
      - /path/to/host2:/data/data2
    restart: unless-stopped
```

This mounts `/path/to/host1` and `/path/to/host2` for syncing. Ensure remote MEGA paths `/path/to/host1` and `/path/to/host2` exist before starting the sync.

## Parameters

| Parameter       | Description                                           | Default Value | Required/Optional |
|-----------------|-------------------------------------------------------|---------------|-------------------|
| `USERNAME`      | Your MEGA email address                               | None          | Required*         |
| `PASSWORD`      | Your MEGA password                                    | None          | Required*         |
| `SESSION`       | Existing MEGA session token                           | None          | Optional*         |
| `PUID`          | User ID for the container (for permissions)           | 0 (root)      | Optional          |
| `PGID`          | Group ID for the container (for permissions)          | 0 (root)      | Optional          |
| `MEGA_PATH`     | Specific path in your MEGA account for default sync   | `/`           | Optional          |
| `MEGA_CMD`      | Comma-separated list of MEGAcmd commands (e.g., sync) | None          | Optional          |

*Either `SESSION` or both `USERNAME` and `PASSWORD` must be provided for authentication.

## Notes
- **Permissions**: Set `PUID` and `PGID` to match the user/group IDs of your host directories to avoid permission issues. The container adjusts ownership of sync paths based on these IDs.
- **Remote Paths**: Ensure remote MEGA paths exist before attempting to sync or you will encounter an error.
- **Filesystem Warnings**: You may see warnings in about unresolved device symlinks (e.g., `Couldn't resolve device symlink`). These are benign and do not affect sync functionality in Docker environments.

## Reporting Issues
For bugs or issues, please create a GitHub issue [here](https://github.com/j3ko/mega-sync/issues). Include:
- Your `docker run` or Docker Compose configuration.
- Container logs (`docker logs mega-sync`).

