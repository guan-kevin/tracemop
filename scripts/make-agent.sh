#!/bin/bash
#
# Create Java agent for TraceMOP
# Usage: make-agent.sh <property-directory> <output-directory> <verbose-mode> <tracking-mode> <trace-dir> <agent-name> <db-conf> [stats] [violation-from-ajc]
# Source: https://github.com/SoftEngResearch/tracemop/blob/master/scripts/make-agent.sh
#
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

if [[ $# != 7 && $# != 8 && $# != 9 ]]; then
    echo "Usage: $0 property-directory output-directory verbose-mode tracking-mode trace-dir agent-name db-conf stats violation-from-ajc"
    echo "       verbose-mode: {verbose|quiet}"
    echo "       tracking-mode: {track|no-track}"
    echo "       db-conf: file containing the database configurations to use"
    echo "       stats: {stats|no-stats}, optional default to no-stats"
    echo "       violation-from-ajc: {true|false}, optional default to true"
    exit
fi

props_dir=$1
out_dir=$2
mode=$3
track=$4
trace_dir=$5
agent_name=$6
db_conf=$7
stats=$8
violation_from_ajc=$9

function build_agent() {
    local agent_name=$1
    local prop_files=${props_dir}/*.mop
    local javamop_flag=""
    local rv_monitor_flag=""

    if [[ ${stats} == "stats" ]]; then
        # statistics: add -s flag to both javamop and rv-monitor
        javamop_flag="-s"
        rv_monitor_flag="-s"
    fi
    
    if [[ ${track} == "track" ]]; then
        # collect traces, add flags to rv-monitor, and add -internalBehaviorObserving to javamop
        javamop_flag="${javamop_flag} -internalBehaviorObserving" # this basically add AspectJ's thisJoinPointStaticPart to method signatures, because to collect traces, we must get location from ajc
        rv_monitor_flag="${rv_monitor_flag} -trackEventLocations -computeUniqueTraceStats -storeEventLocationMapFile -artifactsDir ${trace_dir} -dbConfigFile ${db_conf}"
    fi
    
    if [[ ${violation_from_ajc} != "false" ]]; then
        # get location from AspectJ (default), add -locationFromAjc flag to both javamop and rv-monitor
        rv_monitor_flag="${rv_monitor_flag} -locationFromAjc"
        javamop_flag="${javamop_flag} -locationFromAjc"
    fi
    
    echo "Flags for javamop: ${javamop_flag}"
    echo "Flags for rv-monitor: ${rv_monitor_flag}"

    cp ${SCRIPT_DIR}/BaseAspect_new.aj ${props_dir}/BaseAspect.aj

    for spec in ${prop_files}; do
        javamop -baseaspect ${props_dir}/BaseAspect.aj -emop ${spec} ${javamop_flag} #-d ${mop_out_dir}
    done

    rm -rf ${props_dir}/classes/mop; mkdir -p ${props_dir}/classes/mop
    
    rv-monitor -merge -d ${props_dir}/classes/mop/ ${props_dir}/*.rvm ${rv_monitor_flag} #-v
    
    javac ${props_dir}/classes/mop/*.java
    if [ "${mode}" == "verbose" ]; then
        echo "AGENT IS VERBOSE!"
        javamopagent -m -emop ${props_dir}/ ${props_dir}/classes -n ${agent_name} -v
    elif [ "${mode}" == "quiet" ]; then
        echo "AGENT IS QUIET!"
        javamopagent -emop ${props_dir}/ ${props_dir}/classes -n ${agent_name} -v
    fi

    if [[ ${out_dir} != "." ]]; then
        mv ${agent_name}.jar ${out_dir}
    fi
}

mkdir -p ${out_dir}
build_agent ${agent_name}
