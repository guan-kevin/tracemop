#!/bin/bash

OUTPUT=$1
ID=$2

while [[ -z ${ID} ]]; do
  ID=$(ps aux | grep "/usr/lib/jvm/java-8-openjdk/jre/bin/java \-javaagent:" | awk '{print $2}')
done

MAX_MEMORY=0
while true; do
  memory=$(ps faux | grep -Fv -e 'grep' -e 'bash' | grep $ID | cut -d '\' -f 1 | awk '{print $6}')
  if [[ ${memory} -eq 0 ]]; then
    if [[ -n ${OUTPUT} ]]; then
      echo "${MAX_MEMORY}" >> ${OUTPUT}
    else
      echo "Max memory: ${MAX_MEMORY}"
    fi
    exit 0
  fi

  if [[ -z ${OUTPUT} ]]; then
    echo "${memory}"
  fi

  if [[ "${memory}" -gt "${MAX_MEMORY}" ]]; then
    MAX_MEMORY=${memory}
  fi

  sleep 1
done
