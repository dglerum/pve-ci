# 1. Download latest Rocky 9 Cloud image (as of Dec 2025)
cd /var/lib/vz/template/iso
wget https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-Cloud-Base.latest.x86_64.qcow2

# 2. Create the VM (9200 = Rocky template)
qm create 9200 \
  --name rocky-9-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/Rocky-9-Cloud-Base.latest.x86_64.qcow2 \
  --scsihw virtio-scsi-single \
  --boot order=scsi0 \
  --serial0 socket --vga serial0 \
  --agent enabled=1 \
  --ostype l26

# 3. Add cloud-init CD-ROM
qm set 9200 --ide2 local-lvm:cloudinit

# 4. Make it a template
qm template 9200

echo "Rocky Linux 9 template created as VMID 9200"
