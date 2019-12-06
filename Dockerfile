# © Copyright IBM Corporation 2019
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

ARG BASE_IMAGE=ubuntu:19.04
FROM $BASE_IMAGE

ARG GOPATH_ARG="/go"

ENV GOVERSION=1.12   \
    GOPATH=$GOPATH_ARG \
    ORG="github.com/ibm-messaging"


# Install the Go compiler and Git
RUN export DEBIAN_FRONTEND=noninteractive \
  && bash -c 'source /etc/os-release; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME} main restricted" > /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-updates main restricted" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-backports main restricted universe" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME} universe" >> /etc/apt/sources.list; \
     echo "deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-updates universe" >> /etc/apt/sources.list;' \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    golang-${GOVERSION} \
    git \
    ca-certificates \
    curl \
    tar \
    bash \
    go-dep \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# Create location for the git clone and MQ installation
RUN mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg \
  && chmod -R 777 $GOPATH \
  && mkdir -p $GOPATH/src/$ORG \
  && mkdir -p /opt/mqm \
  && chmod a+rx /opt/mqm

# Location of the downloadable MQ client package \
ENV RDURL="https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist" \
    RDTAR="IBM-MQC-Redist-LinuxX64.tar.gz" \
    VRMF=9.1.3.0

# Install the MQ client from the Redistributable package. This also contains the
# header files we need to compile against.
RUN cd /opt/mqm \
 && curl -LO "$RDURL/$VRMF-$RDTAR" \
 && tar -zxf ./*.tar.gz \
 && rm -f ./*.tar.gz

# Insert the script that will do the build
COPY buildInDocker.sh $GOPATH
RUN chmod 777 $GOPATH/buildInDocker.sh

# Copy the rest of the source tree from this directory into the container and
# make sure it's readable by the user running the container
ENV  REPO="mq-metric-samples"
COPY . $GOPATH/src/$ORG/$REPO
RUN chmod -R a+rwx $GOPATH/src/$ORG/$REPO

# Set the entrypoint to the script that will do the compilation
ENTRYPOINT $GOPATH/buildInDocker.sh
