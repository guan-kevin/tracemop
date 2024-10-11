#!/bin/bash
#
# Run TraceMOP in Docker
# Before running this script, run `docker login`
# Usage: run_in_docker.sh <projects-list> <output-dir> [branch=false] [timeout=86400s]
#
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

PROJECTS_LIST=$1
OUTPUT_DIR=$2
BRANCH=$3
TIMEOUT=$4

function check_input() {
  if [[ ! -f ${PROJECTS_LIST} || -z ${OUTPUT_DIR} ]]; then
    echo "Usage: run_in_docker.sh <projects-list> <output-dir> [branch=false] [timeout=86400s]"
    exit 1
  fi

  if [[ ! ${OUTPUT_DIR} =~ ^/.* ]]; then
    OUTPUT_DIR=${SCRIPT_DIR}/${OUTPUT_DIR}
  fi

  mkdir -p ${OUTPUT_DIR}

  if [[ ! -s ${PROJECTS_LIST} ]]; then
    echo "${PROJECTS_LIST} is empty..."
    exit 0
  fi

  if [[ -z $(grep "###" ${PROJECTS_LIST}) ]]; then
    echo "You must end your projects-list file with ###"
    exit 1
  fi

  if [[ -z ${TIMEOUT} ]]; then
    TIMEOUT=86400s
  fi
}


function run_project() {
  local repo=$1

  sha=$(echo "${repo}" | cut -d ',' -f 2)
  repo=$(echo "${repo}" | cut -d ',' -f 1)

  local project_name=$(echo ${repo} | tr / -)

  local start=$(date +%s%3N)
  echo "Running ${project_name} with SHA ${sha}"
  mkdir -p ${OUTPUT_DIR}/${project_name}

  local id=$(docker run -itd --name ${project_name} pigzy/workspace:tracemop)
  docker exec -w /home/tracemop/tracemop ${id} git pull
  if [[ $? -ne 0 ]]; then
    echo "Unable to pull, try again in 10 seconds"
    sleep 10
    docker exec -w /home/tracemop/tracemop ${id} git pull
    if [[ $? -ne 0 ]]; then
      echo "Skip ${project_name} because script can't pull" &>> ${OUTPUT_DIR}/${project_name}/docker.log
      return
    fi
  fi
  
  if [[ -n ${BRANCH} && ${BRANCH} != "false" ]]; then
    docker exec -w /home/tracemop/tracemop ${id} git checkout ${BRANCH} 
    docker exec -w /home/tracemop/tracemop ${id} git pull
  fi
  
  echo "Not collecting traces"
  timeout ${TIMEOUT} docker exec -w /home/tracemop/tracemop -e M2_HOME=/home/tracemop/apache-maven -e MAVEN_HOME=/home/tracemop/apache-maven -e CLASSPATH=/home/tracemop/aspectj-1.9.7/lib/aspectjtools.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjrt.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar: -e PATH=/home/tracemop/apache-maven/bin:/usr/lib/jvm/java-8-openjdk/bin:/home/tracemop/aspectj-1.9.7/bin:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${id} timeout ${TIMEOUT} bash scripts/run_tracemop.sh ${repo} ${sha} /home/tracemop/output false true true &>> ${OUTPUT_DIR}/${project_name}/docker.log
  
  echo "Collecting traces"
  timeout ${TIMEOUT} docker exec -w /home/tracemop/tracemop -e M2_HOME=/home/tracemop/apache-maven -e MAVEN_HOME=/home/tracemop/apache-maven -e CLASSPATH=/home/tracemop/aspectj-1.9.7/lib/aspectjtools.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjrt.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar: -e PATH=/home/tracemop/apache-maven/bin:/usr/lib/jvm/java-8-openjdk/bin:/home/tracemop/aspectj-1.9.7/bin:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${id} timeout ${TIMEOUT} bash scripts/run_tracemop.sh ${repo} ${sha} /home/tracemop/output true true &>> ${OUTPUT_DIR}/${project_name}/docker.log
  
  timeout ${TIMEOUT} docker exec ${id} mv /home/tracemop/tracemop/scripts/old-track-no-stats-agent.jar /home/tracemop/tracemop/scripts/track-no-stats-agent.jar
  
  echo "Collecting traces using ISSTA agent"
  timeout ${TIMEOUT} docker exec -w /home/tracemop/tracemop -e M2_HOME=/home/tracemop/apache-maven -e MAVEN_HOME=/home/tracemop/apache-maven -e CLASSPATH=/home/tracemop/aspectj-1.9.7/lib/aspectjtools.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjrt.jar:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar: -e PATH=/home/tracemop/apache-maven/bin:/usr/lib/jvm/java-8-openjdk/bin:/home/tracemop/aspectj-1.9.7/bin:/home/tracemop/aspectj-1.9.7/lib/aspectjweaver.jar:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${id} timeout ${TIMEOUT} bash scripts/run_tracemop.sh ${repo} ${sha} /home/tracemop/output/old-tracemop true true &>> ${OUTPUT_DIR}/${project_name}/docker.log

  docker cp ${id}:/home/tracemop/output ${OUTPUT_DIR}/${project_name}/output

  docker rm -f ${id}
  
  local end=$(date +%s%3N)
  local duration=$((end - start))
  echo "Finished running ${project_name} in ${duration} ms" &>> ${OUTPUT_DIR}/${project_name}/docker.log
}

function run_all() {
  while true; do
    if [[ ! -s ${PROJECTS_LIST} ]]; then
      echo "${PROJECTS_LIST} is empty..."
      exit 0
    fi

    local project=$(head -n 1 ${PROJECTS_LIST})
    if [[ ${project} == "###" ]]; then
      echo "Finished running all projects"
      exit 0
    fi

    if [[ -z $(grep "###" ${PROJECTS_LIST}) ]]; then
      echo "You must end your projects-list file with ###"
      exit 1
    fi

    sed -i 1d ${PROJECTS_LIST}
    echo $project >> ${PROJECTS_LIST}
    run_project ${project} $@
  done
}

check_input
run_all $@
