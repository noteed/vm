ubuntu-14.04.2-server-amd64.img: ubuntu-14.04.2-server-amd64-unattended.iso
	rm -f ubuntu-14.04.2-server-amd64.img
	qemu-img create -f qcow2 ubuntu-14.04.2-server-amd64.img 8G
	kvm -nographic -no-reboot -m 256 -cdrom ubuntu-14.04.2-server-amd64-unattended.iso -boot d ubuntu-14.04.2-server-amd64.img

ubuntu-14.04.2-server-amd64-unattended.iso: seed.seed setup-docker-tinc.sh make-iso.sh
	sudo ./make-iso.sh
