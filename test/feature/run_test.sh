#!/bin/bash
set -e

scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cluster_url="http://localhost:8080"
timeout=60

# Root user credentials — exported for docker compose so db-init creates the superuser.
# These must match [s3 main] in s3tests.conf so the main test user is ready from the start.
export UH_ROOT_USER="main"
export UH_ROOT_ACCESS_KEY="0555b35654ad1656d804"
export UH_ROOT_SECRET_KEY="h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=="

compose_file="$scriptdir/../../docker/docker-compose.yaml"

docker compose -f "$compose_file" build
docker compose -f "$compose_file" up --detach

# Wait for the cluster to respond
for ((t = 0; t < timeout; ++t)); do
    if curl -so /dev/null "$cluster_url"; then
        break
    fi
    sleep 1
done

if ((t == timeout)); then
    echo "Cluster did not become ready in time" >&2
    docker compose -f "$compose_file" down --volume
    exit 1
fi

# Create additional test users with credentials derived from username
export AWS_ACCESS_KEY_ID="$UH_ROOT_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$UH_ROOT_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"
aws_cmd=(aws --endpoint-url "$cluster_url" --no-verify-ssl)

create_user() {
    local username="$1"
    "${aws_cmd[@]}" iam create-user --user-name "$username"
    docker compose -f "$compose_file" run --rm --no-deps \
        -e UH_DB_HOSTPORT=db:5432 \
        -e UH_DB_USER=postgres \
        -e UH_DB_PASS=uh \
        coordinator \
        uh-access key-add "$username" "$username" "${username}-pass" 2000000000
}

create_user "alt"
create_user "tenant"
create_user "iam"

export S3TEST_CONF="$scriptdir/s3tests.conf"

deselect_args=()
skip_list="$scriptdir/s3tests_skip.txt"
if [ -f "$skip_list" ]; then
    while IFS= read -r test_id; do
        [[ -z "$test_id" || "$test_id" == \#* ]] && continue
        deselect_args+=(--deselect "$test_id")
    done < "$skip_list"
fi

(cd "$scriptdir" && pytest "s3-tests/s3tests/functional/test_s3.py" "${deselect_args[@]}")

docker compose -f "$compose_file" down --volume
