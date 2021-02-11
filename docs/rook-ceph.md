# Rook-Ceph

**NOTE**: We had an issue with `ceph/ceph:v15.2.8` where it wont create OSDs. Error message is always that the already wiped disks contains an LVM partition. Seems like ceph creates one and then can't use it for some reason. Last known working version is `ceph/ceph:v15.2.7` so roll back to that version if needed.

## Get dashboard password
Get admin password:

```shell
$ kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

## Troubleshooting

On occation we got in a state where the filesystem was degraded but everything else seems to be working fine. No errors no error logs.

What we did to fix this was to delete each `rook-ceph-mds-myfs-*` pod one at the time. Let the first pod restart before killing the second one.

## Delete PV
You can delete the PV using following two commands:

```shell
$ kubectl delete pv <pv_name> --grace-period=0 --force
```

And then deleting the finalizer using:

```shell
$ kubectl patch pv <pv_name> -p '{"metadata": {"finalizers": null}}'`
```

## Wipe disks

```bash
#!/usr/bin/env bash
DISK="/dev/sda"
# Zap the disk to a fresh, usable state (zap-all is important, b/c MBR has to be clean)
# You will have to run this step for all disks.
sgdisk --zap-all $DISK
# Clean hdds with dd
dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
# Clean disks such as ssd with blkdiscard instead of dd
blkdiscard $DISK

# These steps only have to be run once on each node
# If rook sets up osds using ceph-volume, teardown leaves some devices mapped that lock the disks.
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
# ceph-volume setup can leave ceph-<UUID> directories in /dev (unnecessary clutter)
rm -rf /dev/ceph-*
```
