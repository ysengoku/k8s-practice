#!/usr/bin/env bash
set -eu

GOINFRE="/goinfre/$USER"
VM_DIR="$GOINFRE/VirtualBox_VMs"
VAGRANT_DIR="$GOINFRE/vagrant.d"

mkdir -p "$VM_DIR" "$VAGRANT_DIR"

VBoxManage setproperty machinefolder "$VM_DIR"

LINE='export VAGRANT_HOME=/goinfre/$USER/vagrant.d'
grep -qxF "$LINE" ~/.zshrc || echo "$LINE" >> ~/.zshrc

VBoxManage list vms | grep '<inaccessible>' | grep -o  '{[^}]*}' | tr -d '{}' |
while read -r uuid; do
    VBoxManage unregistervm "$uuid"
done

source ~/.zshrc

echo "Done. Now, run: vagrant up"
