set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

build-image tag="fleet:local":
  docker buildx build --platform linux/amd64 -f Dockerfile.multiarch --load -t {{tag}} .

build-image-amd64 tag="fleet:amd64":
  docker buildx build --platform linux/amd64 -f Dockerfile.multiarch --load -t {{tag}} .

helm-template:
  helm template fleet ./charts/fleet -f ./charts/fleet/values-koshee.yaml

sync-upstream ref="main":
  ./scripts/sync-upstream.sh {{ref}}
