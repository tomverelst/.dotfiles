#/bin/bash


set -e

function install-krew () {
  cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
}

function install-krew-plugins () {
  kubectl krew install ctx
  kubectl krew install ns
  kubectl krew install tree
  kubectl krew install access-matrix
  kubectl krew install kuttl
  kubectl krew install stern
}
