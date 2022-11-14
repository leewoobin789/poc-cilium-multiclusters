#!/bin/bash

add_chart() {
    NAME="${1}"
    URL="${2}"

    echo "Check existence of $NAME helm repo"
    REPO_EXISTENCE=$(helm repo list | grep "$URL")

    if [ -z "${REPO_EXISTENCE}" ]; then 
        echo "$NAME helm chart repo is being added"
        helm repo add $NAME $URL
    fi
}