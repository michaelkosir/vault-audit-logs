#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "generating audit events..."
# Check if VAULT_ADDR is set
if [ -z "$VAULT_ADDR" ]; then
    echo "VAULT_ADDR is not set. Please enter HCP vault hostname or set the VAULT_ADDR environment variable:"
    read VAULT_ADDR
    echo $VAULT_ADDR
    export VAULT_ADDR=$VAULT_ADDR
else
    echo "Using existing VAULT_ADDR: $VAULT_ADDR if this is not the Vault you want, run 'unset VAULT_ADDR'"
fi
# Check if VAULT_TOKEN is set
if [ -z "$VAULT_TOKEN" ]; then
    echo "VAULT_TOKEN is not set. Please enter HCP Vault Admin token:"
    read VAULT_TOKEN
    export VAULT_TOKEN=$VAULT_TOKEN
    export HCP_ADMIN_VAULT_TOKEN=$VAULT_TOKEN
else
    echo "Using existing VAULT_TOKEN that was set previously. If you get access denied messages, run 'unset VAULT_TOKEN'"
fi

export VAULT_NAMESPACE=admin

names=(
    "alice" "bob" "charlie" "david" "emma" "frank" "grace" "hannah" "ivy" "jack"
    "katie" "liam" "mia" "nathan" "olivia" "paul" "quinn" "rachel" "sam" "tina"
    "ursula" "victor" "wendy" "xander" "yara" "zach"
)

for name in "${names[@]}"; do
  export VAULT_TOKEN=$(vault login -token-only -method=userpass username=$name password=$name)
  echo "running kv put and get for $name in their kv/users directory"

  vault kv put kv/users/$name/demo db_user=$RANDOM db_password=$(uuidgen) > /dev/null
  vault kv put kv/users/$name/example api_key=$(uuidgen) > /dev/null

  vault kv list kv/users/$name > /dev/null

  # Loop random number of times
  for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
    vault kv get kv/users/$name/demo > /dev/null
  done

done

for name in "${names[@]}"; do
  export VAULT_TOKEN=$HCP_ADMIN_VAULT_TOKEN
  echo "using approle and logging in with $name, then running kv put on their kv/svc directory"
  r=$(vault read -field=role_id auth/approle/role/svc-${name:0:1}/role-id)
  s=$(vault write -f -field=secret_id auth/approle/role/svc-${name:0:1}/secret-id)

  export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$r secret_id=$s)

  vault kv put kv/svc/svc-${name:0:1}/db db_user=$RANDOM db_password=$RANDOM > /dev/null

  if [ $((RANDOM % 100 + 1)) -le 25 ]; then
    # 25% chance
    vault kv put kv/svc/svc-${name:0:1}/api api_key=$(uuidgen) > /dev/null

    for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
      vault kv get kv/svc/svc-${name:0:1}/api > /dev/null
    done
  fi

  # Loop random number of times
  for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
    vault kv get kv/svc/svc-${name:0:1}/db > /dev/null
  done
done
