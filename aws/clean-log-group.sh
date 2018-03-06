#!/usr/bin/env bash
set -e

log_group=${1}

if [ "x$log_group" == "x" ]; then
    echo "Usage: ${0} <log_group>"
    exit 1
fi

log_streams=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --query 'logStreams[].logStreamName' --output text)
for i in $(echo ${log_streams}); do
    echo "- $i"
    aws logs delete-log-stream --log-group-name $LOG_GROUP --log-stream-name $i
done
