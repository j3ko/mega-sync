# mega-sync
Dockerized [Mega](https://mega.nz) sync utility built on [MEGAcmd](https://mega.io/cmd).

## Default Sync
Run the container with your MEGA account credentials to sync files or execute commands:
```bash
docker run --name=mega-sync \
  -e USERNAME="your-mega-email@example.com" \
  -e PASSWORD="your-mega-password" \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/host:/data \
  j3ko/mega-sync:latest
```
This will continually sync `/path/to/host` to the root of your mega account.

## Sync with specific MEGA path
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
This will sync `/path/to/host` to `/path/in/mega`.


## Parameters

| Parameter       | Description                                | Default Value | Required/Optional |
|-----------------|--------------------------------------------|---------------|-------------------|
| `USERNAME`      | Your MEGA email address                    | None          | Required          |
| `PASSWORD`      | Your MEGA password                         | None          | Required          |
| `SESSION`       | Existing MEGA session token                | None          | Optional          |
| `PUID`          | User ID for the container                  | 0             | Optional          |
| `PGID`          | Group ID for the container                 | 0             | Optional          |
| `MEGA_PATH`     | Specific path in your MEGA account         | `/`           | Optional          |

## Reporting Issues

For bugs and issues, please create a GitHub issue [here](https://github.com/j3ko/mega-sync/issues).

