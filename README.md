# K3s Homelab

Self-hosted services running on a single-node k3s cluster with Traefik ingress and Tailscale access.

## Architecture

```mermaid
flowchart TB
    Users["Users"] -->|Tailscale VPN| Traefik["Traefik Ingress\n(HTTPS)"]
    Traefik -->|Auth Check| Tinyauth["Tinyauth"]
    Traefik --> Services
    
    subgraph Services["Applications"]
        direction TB
        
        subgraph Media["Media"]
            Plex["watch.manosriram.com\n(Plex)"]
            Immich["photos.manosriram.com\n(Immich)"]
            MeTube["youtube.manosriram.com\n(MeTube)"]
        end
        
        subgraph Productivity["Productivity"]
            Paperless["drive.manosriram.com\n(Paperless)"]
            Vaultwarden["passwords.manosriram.com\n(Vaultwarden)"]
            Linkding["bookmarks.manosriram.com\n(Linkding)"]
            Miniflux["rss.manosriram.com\n(Miniflux)"]
        end
        
        subgraph Tools["Tools"]
            qBittorrent["torrent.manosriram.com"]
            Syncthing["sync.manosriram.com"]
            Copyparty["ftp.manosriram.com"]
            Kakeibo["Kakeibo (NodePort)"]
        end
        
        subgraph System["System"]
            Headlamp["infra.manosriram.com\n(K8s Dashboard)"]
            Gatus["health.manosriram.com\n(Uptime)"]
            Beszel["stats.manosriram.com\n(Metrics)"]
            Cronicle["cron.manosriram.com\n(Scheduler)"]
            Velero["Velero\n(Backup)"]
        end
        
        subgraph Storage["Storage"]
            MinIO["MinIO\n(Backup Storage)"]
        end
        
        Velero --> MinIO
        
        subgraph Auth["Identity"]
            Tinyauth["auth.manosriram.com\n(Login Portal)"]
            PocketID["id.manosriram.com\n(SSO Provider)"]
        end
    end
```

## Access

All services are accessible via **Tailscale VPN** at `100.69.69.69`. Services with Tinyauth protection require login through `auth.manosriram.com` first.

## Deployment

```bash
# Deploy everything
kubectl apply -f k3s/manifests/ --recursive

# Deploy specific app
kubectl apply -f k3s/manifests/immich/

# Check status
kubectl get pods -A


# Or simply use scripts/k3s-deploy.sh
cp k3s-deploy /usr/local/bin;
k3s-deploy -d <dir> -n <namespace> deploy|delete
```

## Backups

- **Velero** for cluster backups (including MinIO) stored in MinIO
- **Daily** at 8:00 AM → Backblaze B2 (30 day retention)
- **Monthly** at 9:00 AM → Backblaze B2 (12 month retention)
- Health checks via healthchecks.io every 10 minutes
