#!/usr/bin/env bash
set -e

profile=${1}

if [ "x$profile" == "x" ]; then
    echo "Usage: ${0} <profile>"
    exit 1
fi

current_key_id=$(aws --profile "${profile}" configure get aws_access_key_id)

username=$(aws --profile "${profile}" iam get-user --query 'User.UserName' --output text)
acces_keys=$(aws --profile "${profile}" iam list-access-keys --query 'AccessKeyMetadata[].AccessKeyId' --output text)

echo -n "Do you want to rotate ${profile}'s access keys (username: ${username})? (yes/no): "
read confirmation
confirmation=$(echo -n ${confirmation})

if [ "x${confirmation}" != "xyes" ]; then
    exit 0
fi

# Delete all keys except for the key defined for the profile
for key in $acces_keys; do
    if [ "x${key}" != "x${current_key_id}" ]; then
        aws --profile "${profile}" iam delete-access-key --access-key-id "${key}"
        echo "Removed key id: ${key}"
    fi
done

# Create new keys
new_keys=$(aws --profile "${profile}" iam create-access-key --query 'AccessKey' --output text)
new_key_id=$(echo "${new_keys}" | awk '{print $1}')
new_access_key=$(echo "${new_keys}" | awk '{print $3}')
echo "New keys created"

# Assign the new keys
aws --profile "${profile}" configure set aws_access_key_id ${new_key_id}
aws --profile "${profile}" configure set aws_secret_access_key ${new_access_key}
echo "Profile re-configured"

export AWS_ACCESS_KEY_ID="${new_key_id}" AWS_SECRET_ACCESS_KEY="${new_access_key}"
sleep 5
aws iam delete-access-key --access-key-id "${current_key_id}" 2>1 > /dev/null || \
(sleep 10 && aws iam delete-access-key --access-key-id "${current_key_id}" 2>1 > /dev/null)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
echo "Removed old key: ${current_key_id}"
