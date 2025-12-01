# Proxmox + GitLab CI – Instant VMs (Ubuntu · Fedora · Rocky)

Just change one variable → get a fresh VM in < 30 seconds.

### Supported OS (just set DISTRO)
- `ubuntu` → VMID 9000 (default user: ubuntu)
- `fedora` → VMID 9100 (default user: fedora)
- `rocky`  → VMID 9200 (default user: rocky)

### Required GitLab CI/CD Variables (masked + protected)
- `SSH_PRIVATE_KEY` → your Ed25519 private key (the one whose pubkey is in `cloud-init/sshkeys-gitlab-ci.pub`)
- `VM_PASSWORD`     → cloud-init password (optional if you only use SSH keys)

### One-time Proxmox setup (you probably already did this)
```bash
# Create CI user + role + permissions
pveum user add gitlab-ci@pve
pveum role add GitLabDeploy -privs "VM.Clone VM.Config.* VM.PowerMgmt VM.Allocate Datastore.AllocateTemplate"
pveum acl modify / --user gitlab-ci@pve --role GitLabDeploy

# Add your SSH public key to Proxmox
cat cloud-init/sshkeys-gitlab-ci.pub >> /var/lib/vz/sshkeys-gitlab-ci.pub
# or copy to /etc/pve/priv/authorized_keys (root) or user home
