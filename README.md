# Ghanizada Cloud Run User Manager v12

v12 keeps the v11 dashboard and adds a complete VPS WebSocket-to-SSH backend workflow.

## VPS backend

The dashboard can generate a one-command Ubuntu/Debian installer. It installs:

- Websockify: WebSocket -> TCP bridge
- Nginx: public WebSocket endpoint with a private backend token
- systemd service for automatic Websockify restart
- forwarding target: `127.0.0.1:22`

Cloud Run remains the public HTTPS/WSS endpoint. The client connects to the Cloud Run hostname and `/ws/ssh`. Cloud Run sends the WebSocket request to the VPS backend and adds the private backend token.

### Setup

1. Deploy this project to Cloud Run.
2. Log in to the dashboard.
3. Open **Settings -> SSH / Stunnel VPS Backend**.
4. Enter the VPS IP/hostname. Defaults are HTTP port `8080` and path `/ws/ssh`.
5. Click **GET ONE-COMMAND INSTALL**.
6. Copy the generated command and run it on an Ubuntu/Debian VPS.
7. Save & Apply the backend in the dashboard.
8. Click **TEST VPS**.
9. In the client use the Cloud Run hostname, port 443, TLS on, WebSocket on, and path `/ws/ssh`.

The SSH payload is carried inside an encrypted SSH session; the Cloud Run-to-VPS backend hop is HTTP by default. The backend token protects the WebSocket bridge from unauthorised Cloud Run requests. If you need TLS between Cloud Run and the VPS, select HTTPS and provide a VPS HTTPS endpoint with a publicly trusted certificate.

## Important Cloud Run WebSocket behavior

Cloud Run supports WebSockets, but WebSocket requests are subject to the configured request timeout. The deploy script uses a 3600-second timeout; clients should reconnect when a stream is closed.

## Existing features

- Trojan / VLESS / VMess
- User CRUD
- QR generation
- Subscription URLs
- Traffic and expiration limits
- Cloud Storage persistence
- Admin authentication
- Backup/restore
- Mobile dashboard
- SSH/VPS backend configuration


### Default panel password
For a new deployment, the default admin panel password is `Ghanizada`. You can change it from **Security** after logging in. Existing deployments keep their existing stored admin password.
