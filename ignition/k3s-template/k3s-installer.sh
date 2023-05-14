#!/usr/bin/env sh
main() {
  # selinux dependencies are handled in prereq script
  export INSTALL_K3S_SKIP_SELINUX_RPM=true
  export INSTALL_K3S_SELINUX_WARN=true

  export K3S_KUBECONFIG_MODE="644"
  export INSTALL_K3S_EXEC="%%% INSTALL OPTS %%%"

  curl -sfL https://get.k3s.io | sh -
  echo "selinux: true" >> /etc/rancher/k3s/config.yaml
  return 0
}
main
