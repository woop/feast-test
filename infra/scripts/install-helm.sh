#!/usr/bin/env bash
set -e
readonly HELM_URL=https://storage.googleapis.com/kubernetes-helm
readonly HELM_TARBALL=helm-v2.16.9-linux-amd64.tar.gz
readonly STABLE_REPO_URL=https://kubernetes-charts.storage.googleapis.com/
readonly INCUBATOR_REPO_URL=https://kubernetes-charts-incubator.storage.googleapis.com/
curl --user-agent curl-ci-sync -sSL -o "$HELM_TARBALL" "$HELM_URL/$HELM_TARBALL"
tar xzfv "$HELM_TARBALL"
PATH="$(pwd)/linux-amd64/:$PATH"
helm init --client-only
helm repo add incubator "$INCUBATOR_REPO_URL"