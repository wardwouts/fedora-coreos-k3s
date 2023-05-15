# Fedora CoreOS + k3s

This builds on the work of:
- https://www.murillodigital.com/tech_talk/k3s_in_coreos/
- https://stevex0r.medium.com/setting-up-a-lightweight-kubernetes-cluster-with-k3s-and-fedora-coreos-12d504160366

And tries to modernize things a bit and automate further.

Creating the ISOs for automatic installation should be as simple as:
```
./01-build-iso.sh -b -t <TOKEN> -u <SERVER URL>
```
This should generate both an `agent.iso` and `server.iso` file. The server URL should have the format of `https://ServerIP:6443`.

Before doing this you will want to add your own public ssh keys to `ignition/k3s-common-ssh_authorized_keys.txt`, so that you can access your own k3s cluster hosts afterwards.

It is also possible to use the script to only create an agent or server ISO. Or evan ISO file for a single node cluster.

The built-in help should be pretty self-explanatory: `./01-build-iso.sh -h`
