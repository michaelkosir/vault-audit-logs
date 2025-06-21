#!/bin/bash
set -e
cd "$(dirname "$0")"

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


echo "creating secrets engines..."
if ! vault auth list -format=json | grep -q '"userpass/"'; then
    vault auth enable userpass > /dev/null
fi
if ! vault auth list -format=json | grep -q '"approle/"'; then
    vault auth enable approle > /dev/null
fi
if ! vault secrets list -format=json | grep -q '"kv/"'; then
    vault secrets enable -version=2 kv > /dev/null
fi
if ! vault secrets list -format=json | grep -q '"database/"'; then
    vault secrets enable database > /dev/null
fi



echo "creating sample userpass/approle ..."
names=(
    "alice" "bob" "charlie" "david" "emma" "frank" "grace" "hannah" "ivy" "jack"
    "katie" "liam" "mia" "nathan" "olivia" "paul" "quinn" "rachel" "sam" "tina"
    "ursula" "victor" "wendy" "xander" "yara" "zach"
)

vault policy write example - > /dev/null <<EOF
path "*" {
  capabilities = ["create","read","update","list","delete"]
}
EOF
for name in "${names[@]}"; do
    echo "creating $name account"
    vault write auth/userpass/users/$name password=$name token_policies=example > /dev/null
    vault write -f auth/approle/role/svc-${name:0:1} token_policies=example > /dev/null
done
