# Rook-Ceph

**NOTE**: We had an issue with `ceph/ceph:v15.2.8` where it wont create OSDs. Error message was that the already wiped disks contains an LVM partition. Seems like ceph creates a new LVM partition and then can't use it for some reason. Last known working version is `ceph/ceph:v15.2.7` so roll back to that version if needed.

## Get dashboard password
Get admin password:

```shell
$ kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

Once the admin user was never created. So we created it manually using this command:
```shell
$ ceph dashboard ac-user-create admin -i /tmp/pwd.txt administrator
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

Use the `ansible/playbooks/nuke-rook-ceph.yaml` Ansible playbook for wiping a drive.
