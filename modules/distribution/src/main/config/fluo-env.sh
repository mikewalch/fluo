# Licensed to the Apache Software Foundation (ASF) under one or more contributor license
# agreements.  See the NOTICE file distributed with this work for additional information regarding
# copyright ownership.  The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.

## Before fluo-env.sh is loaded, these environment variables are set and can be used in this file:

# cmd - Command that is being called such as oracle, worker, etc.
# app - Fluo application name 
# basedir - Root of Accumulo installation
# bin - Directory containing Accumulo scripts
# conf - Directory containing Accumulo configuration
# lib - Directory containing Accumulo libraries

############################
# Variables that must be set
############################

## Fluo logs directory. Referenced by logger config.
export FLUO_LOG_DIR="${FLUO_LOG_DIR:-${basedir}/logs}"
## Hadoop installation
export HADOOP_PREFIX="${HADOOP_PREFIX:-/path/to/hadoop}"

##################################################################
# Build JAVA_OPTS variable. Defaults below work but can be edited.
##################################################################

export FLUO_LOG_ID="${app}_${cmd}_$(hostname)_$(date +%s)"

JAVA_OPTS=("-Dlog4j.configuration=file:${conf}/log4j.properties"
           "-Dfluo.log.dir=${FLUO_LOG_DIR}"
           "-Dfluo.log.id=${FLUO_LOG_ID}")
export JAVA_OPTS

##########################
# Build CLASSPATH variable
##########################

# The classpath for Fluo must be defined.  The Fluo tarball does not include
# jars for Accumulo, Zookeeper, or Hadoop.  This example env file offers two
# ways to setup the classpath with these jars.  Go to the end of the file for
# more info.

addToClasspath() 
{
  local dir=$1
  local filterRegex=$2

  if [ ! -d "$dir" ]; then
    echo "ERROR $dir does not exist or not a directory"
    exit 1
  fi

  for jar in $dir/*.jar; do
    if ! [[ $jar =~ $filterRegex ]]; then
       CLASSPATH="$CLASSPATH:$jar"
    fi
  done
}


# This function attemps to obtain Accumulo, Hadoop, and Zookeeper jars from the
# location where those dependencies are installed on the system.
setupClasspathFromSystem()
{
  test -z "$ACCUMULO_HOME" && ACCUMULO_HOME=/path/to/accumulo
  test -z "$ZOOKEEPER_HOME" && ZOOKEEPER_HOME=/path/to/zookeeper

  CLASSPATH="$lib/*"
  if [ -f "$conf/connection.properties" ]; then
    CLASSPATH="$CLASSPATH:$lib/log4j/*"
  else
    CLASSPATH="$CLASSPATH:$lib/twill/*:$lib/logback/*"
  fi

  #any jars matching this pattern is excluded from classpath
  EXCLUDE_RE="(.*log4j.*)|(.*asm.*)|(.*guava.*)|(.*gson.*)"

  addToClasspath "$ACCUMULO_HOME/lib" $EXCLUDE_RE
  addToClasspath "$ZOOKEEPER_HOME" $EXCLUDE_RE
  addToClasspath "$ZOOKEEPER_HOME/lib" $EXCLUDE_RE
  addToClasspath "$HADOOP_PREFIX/share/hadoop/common" $EXCLUDE_RE;
  addToClasspath "$HADOOP_PREFIX/share/hadoop/common/lib" $EXCLUDE_RE;
  addToClasspath "$HADOOP_PREFIX/share/hadoop/hdfs" $EXCLUDE_RE;
  addToClasspath "$HADOOP_PREFIX/share/hadoop/hdfs/lib" $EXCLUDE_RE;
  addToClasspath "$HADOOP_PREFIX/share/hadoop/yarn" $EXCLUDE_RE;
  addToClasspath "$HADOOP_PREFIX/share/hadoop/yarn/lib" $EXCLUDE_RE;
  export CLASSPATH
}


# This function obtains Accumulo, Hadoop, and Zookeeper jars from
# $lib/ahz/. Before using this function, make sure you run
# `./lib/fetch.sh ahz` to download dependencies to this directory.
setupClasspathFromLib(){
  CLASSPATH="$lib/*"
  if [ -f "$conf/connnection.properties" ]; then
    CLASSPATH="$CLASSPATH:$lib/log4j/*"
  else
    CLASSPATH="$CLASSPATH:$lib/logback/*"
  fi
  CLASSPATH="$CLASSPATH:$lib/ahz/*"
  export CLASSPATH
}

# Call one of the following functions to setup the classpath or write your own
# bash code to setup the classpath for Fluo. You must also run the command
# `./lib/fetch.sh extra` to download extra Fluo dependencies before using Fluo.

setupClasspathFromSystem
#setupClasspathFromLib
