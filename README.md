# Fedora CoreOS + k3s

This builds on the work of:
- https://www.murillodigital.com/tech_talk/k3s_in_coreos/
- https://stevex0r.medium.com/setting-up-a-lightweight-kubernetes-cluster-with-k3s-and-fedora-coreos-12d504160366

And tries to modernize things a bit and automate further.

Creating the ISOs for automatic installation should be as simple as:
```
./01-build-iso.sh -b -t <TOKEN> -u <SERVER URL>
```
This should generate both an `agent.iso` and `server.iso` file. The server URL shoudl have the format of `https://ServerIP:6443`.

Before doing this you will want to add your own public ssh keys to `ignition/k3s-common-ssh_authorized_keys.txt`, so that you can access your own k3s cluster hosts afterwards.

It is also possible to use the script to only create an agent or server ISO. It should be pretty self-explanatory:

```
$ ./01-build-iso.sh -h
Tool to build iso files for creating k3s nodes on fedora coreos

Usage:
./01-build-iso.sh [-abh] [-u serverurl] -t <token>

-a              Create ISO for agent, default is server
-b              Create both server and agent ISOs
-h              This help message
-s              Single node (can't be used with -a/-b)
-t <token>      Use this token for cluster
-u <serverurl>  Server URL (needed with -a/-b)
```
