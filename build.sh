#!/bin/bash

DOCKER_USER="nexsre"
DOCKER_PASSWORD="ed!aOGt&4LVOlP"
DOCKER_REGISTRY="docker.io"  # 例如: docker.io 或 registry.cn-hangzhou.aliyuncs.com
TTYD_VERSION="1.4.2"

SHOULD_PUSH=true
[[ -z "${DOCKER_USER}" ]] && SHOULD_PUSH=false
[[ -z "${DOCKER_PASSWORD}" ]] && SHOULD_PUSH=false

echo "Downloading latest ttyd"
rm "./ttyd_linux.x86_64" >/dev/null 2>&1
wget -q "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION:-1.4.2}/ttyd_linux.x86_64" -O "./ttyd_linux.x86_64"
if [[ ! -f "./ttyd_linux.x86_64" ]]; then
  echo "Failed to download ttyd"
  exit 1
fi

if $SHOULD_PUSH; then
  docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" "$DOCKER_REGISTRY"
fi

for IMAGE_NAME in $(cat manifest.json | grep osCode\":\ \"nexsre | grep -o 'nexsre[^"]*'); do
  SUFFIX=`echo ${IMAGE_NAME##*/}`
  OS=${SUFFIX%:*}
  VERSION=${SUFFIX##*:}
  DOCKERFILE="./os/$OS/Dockerfile-$VERSION"

  echo ""
  echo "##########################################################################"
  echo "##  Building $IMAGE_NAME using $DOCKERFILE"
  echo "##########################################################################"
  # docker pull "$IMAGE_NAME" || true
      # --cache-from "$IMAGE_NAME" \
  docker build \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
    -t "$IMAGE_NAME" \
    -f "$DOCKERFILE" \
    . \
    || exit 1
  
  if $SHOULD_PUSH; then
    docker push "$IMAGE_NAME"
  fi
done
