# FTP Server Setup Guide

## Overview

An FTP server container has been added as a bonus feature to provide file management access to the WordPress website files.

## Implementation Details

### Architecture
- **Base Image**: Alpine Linux 3.21
- **FTP Server**: vsftpd (Very Secure FTP Daemon)
- **Volume**: Shares the `wordpress_data` volume with WordPress container
- **Network**: Connected to `inception_network`
- **Ports**: 21 (control), 21000-21010 (passive mode data transfer)

### Files Created

1. **srcs/requirements/bonus/ftp-server/Dockerfile**
   - Custom Dockerfile based on Alpine 3.21
   - Installs vsftpd and bash
   - Follows subject requirements (no ready-made images)

2. **srcs/requirements/bonus/ftp-server/conf/vsftpd.conf**
   - Runs in foreground mode (proper PID 1, no daemon)
   - Passive mode enabled for Docker networking
   - Chroot enabled for security
   - Anonymous access disabled

3. **srcs/requirements/bonus/ftp-server/tools/docker-entrypoint.sh**
   - Creates FTP user dynamically
   - Reads password from Docker secrets
   - Sets proper permissions on WordPress directory
   - Uses `exec` for proper signal handling

4. **srcs/requirements/bonus/ftp-server/.dockerignore**
   - Excludes unnecessary files from build context

### Docker Compose Configuration

The FTP service has been added to `srcs/docker-compose.yml` with:
- Container name: `ftp`
- Depends on: WordPress (waits for it to be healthy)
- Restart policy: `always`
- Health check: Monitors vsftpd process
- Secrets: Uses `ftp_user_password` from secrets file

### Security

- **Password Management**: FTP password stored in `secrets/ftp_user_password.txt`
- **No Hardcoded Credentials**: All passwords use Docker secrets
- **Chroot Jail**: FTP user is restricted to WordPress directory
- **Local Users Only**: Anonymous FTP is disabled

## Usage

### Prerequisites

1. Create the FTP password file:
   ```bash
   echo "your_secure_password" > secrets/ftp_user_password.txt
   ```

2. (Optional) Set custom FTP username in `srcs/.env`:
   ```bash
   FTP_USER=your_username
   ```
   Default username is `ftpuser` if not specified.

### Starting the FTP Server

```bash
# Build and start all services (including FTP)
make

# Or rebuild everything
make re
```

### Connecting to FTP Server

**Using Command Line FTP Client:**
```bash
ftp localhost 21
# Username: ftpuser (or your custom username)
# Password: (from secrets/ftp_user_password.txt)
```

**Using FileZilla or Other GUI Clients:**
- Host: `localhost` or `127.0.0.1`
- Port: `21`
- Protocol: `FTP` (not SFTP)
- Username: `ftpuser` (or your custom username)
- Password: (from secrets/ftp_user_password.txt)

### Available Operations

Once connected, you can:
- Upload files to WordPress directory
- Download WordPress files
- Manage themes in `/wp-content/themes/`
- Manage plugins in `/wp-content/plugins/`
- Manage uploads in `/wp-content/uploads/`
- Edit configuration files

## Verification

### Check FTP Container Status
```bash
docker-compose -f srcs/docker-compose.yml ps
# Should show 'ftp' container as 'running' and 'healthy'
```

### Check FTP Logs
```bash
docker logs ftp
```

### Test FTP Connection
```bash
# Quick connection test
ftp -n localhost 21 <<EOF
user ftpuser your_password
ls
quit
EOF
```

### Verify WordPress Volume Access
```bash
# Check files in WordPress volume
docker exec ftp ls -la /var/www/html
```

## Troubleshooting

### Connection Refused
- Ensure FTP container is running: `docker ps | grep ftp`
- Check port 21 is not used by another service: `sudo lsof -i :21`
- Verify firewall allows FTP connections

### Authentication Failed
- Verify password in `secrets/ftp_user_password.txt`
- Check FTP username matches environment variable
- Review FTP logs: `docker logs ftp`

### Passive Mode Issues
- Ensure ports 21000-21010 are accessible
- Check firewall rules for passive port range
- Verify `pasv_address` in vsftpd.conf

### Permission Denied
- FTP user owns WordPress directory
- Check file permissions: `docker exec ftp ls -la /var/www/html`
- Verify chroot settings in vsftpd.conf

## Technical Compliance

### Subject Requirements ✓
- [x] Custom Dockerfile (no ready-made images)
- [x] Alpine Linux base image
- [x] Dedicated container for FTP service
- [x] Points to WordPress volume
- [x] No infinite loops or hacky patches
- [x] Proper PID 1 (vsftpd runs in foreground)
- [x] Uses Docker secrets (no passwords in Dockerfile)
- [x] Restart on crash (`restart: always`)
- [x] Connected to Docker network
- [x] Health check implemented

### Best Practices ✓
- [x] Entrypoint script uses `exec` for proper signal handling
- [x] No daemon mode (runs in foreground)
- [x] Chroot enabled for security
- [x] Anonymous access disabled
- [x] Proper logging enabled
- [x] Follows existing project patterns

## Integration with WordPress

The FTP server provides direct access to WordPress files, allowing:
- **Theme Development**: Upload and modify themes
- **Plugin Management**: Install and configure plugins
- **Media Management**: Upload images and files
- **Backup**: Download WordPress files for backup
- **Configuration**: Edit wp-config.php and other settings

**Note**: Changes made via FTP are immediately reflected in WordPress since they share the same volume.

## Additional Notes

- FTP runs on standard port 21 (not encrypted)
- For production, consider using SFTP or FTPS
- The FTP user has full read/write access to WordPress directory
- Maximum 10 concurrent connections (configurable in vsftpd.conf)
- Passive mode uses ports 21000-21010 (10 concurrent data connections)

## References

- [vsftpd Documentation](https://security.appspot.com/vsftpd.html)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [FTP Passive Mode](https://www.jscape.com/blog/active-v-s-passive-ftp-simplified)
