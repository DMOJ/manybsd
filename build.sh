#!/bin/bash

rm -f bin/*.so

qemu-system-x86_64 -enable-kvm -nographic -serial file:qemu.log -device virtio-rng-pci -drive format=qcow2,file=freebsd-6.0-amd64.qcow2 -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::2222-:22 > /dev/null &
qemu_pid=$!

echo -n "Started QEMU process ${qemu_pid}, waiting for it to start..."

while ! nc -z localhost 2222; do
  sleep 1
done

echo " done."

echo "Copying source files to VM..."
scp -P2222 -oHostKeyAlgorithms=+ssh-dss -r build/* root@localhost:/build
echo "Compiling..."
ssh -oHostKeyAlgorithms=+ssh-dss root@localhost -p2222 'cd /build && make setbufsize32.so'
echo "Copying artifacts out of VM..."
scp -P2222 -oHostKeyAlgorithms=+ssh-dss root@localhost:/build/*.so bin
echo "Done!"

kill -KILL ${qemu_pid}
