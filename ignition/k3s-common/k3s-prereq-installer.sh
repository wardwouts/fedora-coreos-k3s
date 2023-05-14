#!/usr/bin/env sh
main() {
  #rpm-ostree install container-selinux
  rpm-ostree install selinux-policy-base
  rpm-ostree install https://rpm.rancher.io/k3s/latest/common/centos/7/noarch/k3s-selinux-0.2-1.el7_8.noarch.rpm
  return 0
}
main
