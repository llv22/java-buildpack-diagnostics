#!/usr/bin/env bash
# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Kill script for use as the parameter of OpenJDK's -XX:OnOutOfMemoryError

# send SIGQUIT (3) signal which triggers a threaddump, don't kill the process
pkill -3 -f .*-XX:OnOutOfMemoryError=.*killjava.*

echo "
Process Status
==============
$(ps -ef)

ulimit
======
$(ulimit -a)

Free Disk Space
===============
$(df -h)
"

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $SCRIPTDIR/jbp-diagnostics-functions.sh
upload_oom_heapdump_to_s3
