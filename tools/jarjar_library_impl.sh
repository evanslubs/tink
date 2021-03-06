#!/usr/bin/env bash

# Copyright 2017 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [[ ! $JAVA_HOME =~ ^/ ]]; then
  JAVA_HOME=$(readlink -f $JAVA_HOME)
fi

OUT=$1
DEPS=$2
RULES_FILE=$3
JARJAR=$4
JAR_BINARY=$5
JAVA_BINARY=$6
TMPDIR=$7/combined

mkdir -p $TMPDIR
for dep in $DEPS; do
  unzip -qq -B $dep -d $TMPDIR
done
pushd $TMPDIR &>/dev/null

# Concatenate similar files in META-INF/services
for file in META-INF/services/*; do
  original=$(echo $file | sed s/"~[0-9]*$"//)
  if [[ "$file" != "$original" ]]; then
    cat $file >> $original
    rm $file
  fi
done

rm META-INF/MANIFEST.MF*
rm -rf META-INF/maven/

duplicate_files=$(find * -type f -regex ".*~[0-9]*$")
for file in $duplicate_files; do
  rm $file;
done

java_files=$(find * -type f -name "*.java")
for file in $java_files; do
  rm $file;
done

$JAR_BINARY cf combined.jar *

popd &>/dev/null

$JAVA_BINARY -jar $JARJAR process $RULES_FILE $TMPDIR/combined.jar $OUT
rm -rf $TMPDIR
