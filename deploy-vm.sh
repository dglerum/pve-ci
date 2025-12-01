#!/bin/bash
set -euo pipefail

# Choose your distro
DISTRO="${DISTRO:-rocky}"          # ubuntu | fedora | rocky
case "$DISTRO" in
  ubuntu) TEMPLATE_ID="${TEMPLATE_ID:-9000}" ; CIUSER=ubuntu ;;
  fedora) TEMPLATE_ID="${TEMPLATE_ID:-9100}" ; CIUSER=fedora ;;
  rocky)  TEMPLATE_ID="${TEMPLATE_ID:-9200}" ; CIUSER=rocky  ;;
  *) echo "Unknown DISTRO: $DISTRO" ; exit 1 ;;
esac

PROXMOX_HOST="${PROXMOX_HOST:-pve.local}"
PROXMOX_USER="${PROXMOX_USER:-gitlab-ci@pve}"
VM_NAME="ci-${DISTRO}-${CI_PIPELINE_ID:-$(date +%s)}"
VM_PASSWORD="${VM_PASSWORD:-SuperSecret123!}"

echo "Deploying ${VM_NAME} (template ${TEMPLATE_ID})..."

NEW_VMID_AND_IP=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes \
  -i ~/.ssh/id_ed25519 "${PROXMOX_USER}@${PROXMOX_HOST}" bash <<EOF
set -euo pipefail

NEXT_VMID=\$(pvesh get /cluster/nextid --start 4000)

qm clone ${TEMPLATE_ID} "\$NEXT_VMID" --full 1 --name "${VM_NAME}"

qm set "\$NEXT_VMID" \
  --ciuser ${CIUSER} \
  --cipassword '${VM_PASSWORD}' \
  --sshkeys /etc/pve/local/sshkeys-gitlab-ci.pub \
  --ipconfig0 ip=dhcp

qm set "\$NEXT_VMID" --tags "gitlab-ci,distro-${DISTRO},pipeline-${CI_PIPELINE_ID:-local}"
qm resize "\$NEXT_VMID" scsi0 +20G
qm start "\$NEXT_VMID"

# Wait for IP (Rocky is fast — < 15s)
for i in {1..40}; do
  IP=\$(qm agent "\$NEXT_VMID" network-get-interfaces 2>/dev/null | \
    jq -r '.[] | select(.name=="ens18" or .name=="eth0") |.ip_addresses[]? | select(. != null and . != "127.0.0.1" and . != "::1")' | head -1)
  [ -n "\$IP" ] && break
  sleep 3
done

echo "\$NEXT_VMID:\${IP:-pending}"
EOF
)

VMID=$(echo "$NEW_VMID_AND_IP" | cut -d: -f1)
VM_IP=$(echo "$NEW_VMID_AND_IP" | cut -d: -f2)

echo "Rocky Linux VM ${VMID} ready at ${VM_IP}!"
echo "VMID=${VMID}" >> deploy.env
echo "VM_IP=${VM_IP}" >> deploy.env
echo "VM_NAME=${VM_NAME}" >> deploy.env
echo "DISTRO=${DISTRO}" >> deploy.env
echo "CIUSER=${CIUSER}" >> deploy.env
