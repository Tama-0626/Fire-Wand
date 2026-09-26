#!/usr/bin/env bash
set -euo pipefail

container_name="fire-wand-e2e"
mods_dir="$PWD/e2e-mods"

cleanup() {
  docker rm -f "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mapfile -t mod_jars < <(find build/libs -maxdepth 1 -type f -name '*.jar' ! -name '*-sources.jar' ! -name '*-dev.jar')
if [[ ${#mod_jars[@]} -ne 1 ]]; then
  printf 'Expected exactly one remapped mod JAR, found %s.\n' "${#mod_jars[@]}" >&2
  find build/libs -maxdepth 1 -type f -name '*.jar' -print >&2
  exit 1
fi

mkdir -p "$mods_dir"
cp "${mod_jars[0]}" "$mods_dir/fire-wand.jar"
chmod -R a+rwx "$mods_dir"

docker run -d \
  --name "$container_name" \
  -e EULA=TRUE \
  -e TYPE=FABRIC \
  -e VERSION=26.3 \
  -e FABRIC_LOADER_VERSION=0.19.5 \
  -e MODRINTH_PROJECTS=fabric-api \
  -e ENABLE_RCON=true \
  -e RCON_PASSWORD=e2e-test-password \
  -e ONLINE_MODE=FALSE \
  -e MEMORY=2G \
  -v "$mods_dir:/data/mods" \
  itzg/minecraft-server:java25 >/dev/null

ready=false
for attempt in {1..180}; do
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null || printf false)" != true ]]; then
    printf 'Minecraft server stopped before becoming ready. Container logs:\n' >&2
    docker logs "$container_name" >&2 || true
    exit 1
  fi

  server_logs="$(docker logs "$container_name" 2>&1 || true)"
  if grep -Fq 'Done (' <<<"$server_logs"; then
    ready=true
    break
  fi
  sleep 2
done

if [[ "$ready" != true ]]; then
  printf 'Minecraft server did not become ready within 6 minutes. Container logs:\n' >&2
  docker logs "$container_name" >&2 || true
  exit 1
fi

rcon_ready=false
for attempt in {0..20}; do
  if rcon_response="$(docker exec "$container_name" rcon-cli list 2>&1)"; then
    rcon_ready=true
    break
  fi

  if [[ "$attempt" -lt 20 ]]; then
    printf 'RCON not ready; retry %s/20 in 15 seconds.\n' "$((attempt + 1))" >&2
    sleep 15
  fi
done

if [[ "$rcon_ready" != true ]]; then
  printf 'RCON did not respond after the initial attempt and 20 retries. Last response: %s\n' "$rcon_response" >&2
  docker logs "$container_name" >&2 || true
  exit 1
fi

printf 'RCON response to list:\n%s\n' "$rcon_response"

server_logs="$(docker logs "$container_name" 2>&1 || true)"
if grep -Eiq '(^|[[:space:]/])(ERROR|FATAL)([[:space:]:\]]|$)|Exception in server tick loop|Crash report|Failed to start' <<<"$server_logs"; then
  printf 'Found an ERROR/FATAL or crash-related message in Minecraft server logs:\n' >&2
  grep -Ein '(^|[[:space:]/])(ERROR|FATAL)([[:space:]:\]]|$)|Exception in server tick loop|Crash report|Failed to start' <<<"$server_logs" >&2
  exit 1
fi

printf 'E2E test passed: Minecraft 26.3 started, RCON responded, and no fatal log errors were found.\n'