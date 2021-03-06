# FROM ubuntu:bionic as cloner

# RUN apt-get update && apt-get install -y git-core git-svn
# RUN git clone git://git.webkit.org/WebKit.git /WebKit

#####################################################################################
FROM ubuntu:bionic as builder

ENV COMMIT 3af5ce129e6636350a887d01237a65c2fce77823

RUN apt-get update && apt-get install -y wget

WORKDIR /tmp

RUN wget --progress=bar:force https://s3-us-west-2.amazonaws.com/archives.webkit.org/WebKit-SVN-source.tar.bz2
RUN tar jxvf WebKit-SVN-source.tar.bz2

WORKDIR /tmp/webkit

RUN apt-get update && apt-get install -y subversion git-core git-svn cmake build-essential python libicu-dev libxml-libxml-perl ninja-build ruby gperf bison flex

# RUN svn switch --relocate http://svn.webkit.org/repository/webkit/trunk https://svn.webkit.org/repository/webkit/trunk
RUN Tools/Scripts/update-webkit
RUN svn up -r245504
# RUN Tools/Scripts/webkit-patch setup-git-clone
RUN DEBIAN_FRONTEND=noninteractive Tools/gtk/install-dependencies
RUN DEBIAN_FRONTEND=noninteractive Tools/Scripts/update-webkitgtk-libs
RUN Tools/Scripts/set-webkit-configuration --debug
RUN Tools/Scripts/build-webkit --gtk --cmakeargs="-GNinja -DENABLE_UNIFIED_BUILDS=OFF" MiniBrowser

#####################################################################################
FROM ubuntu:bionic

LABEL maintainer "https://github.com/blacktop"

ENV GDB_VERSION 8.1-0ubuntu3

RUN buildDeps='ca-certificates git build-essential python3-pip' \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -yq $buildDeps \
                         python3 \
                         locales \
                         gdb=$GDB_VERSION \
                         gdb-multiarch=$GDB_VERSION \
  && echo "===> Fix locale..." \
  && locale-gen en_US.UTF-8 \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && echo "===> Install pwndbg..." \
  && export PIP_NO_CACHE_DIR=off \
  && export PIP_DISABLE_PIP_VERSION_CHECK=on \
  && pip3 install --upgrade pip wheel setuptools \
  && cd /root \
  && git clone https://github.com/pwndbg/pwndbg \
  && cd pwndbg \
  && ./setup.sh \
  && echo "===> Clean up unnecessary files..." \
  && apt-get purge -y --auto-remove $buildDeps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update && apt-get install -y bubblewrap rlwrap \
  && echo "===> Clean up unnecessary files..." \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=builder /tmp/webkit/WebKitBuild/Debug/bin /webkit/WebKitBuild/Debug/bin
COPY --from=builder /tmp/webkit/WebKitBuild/Debug/bin /webkit/WebKitBuild/Debug/bin
COPY --from=builder /tmp/webkit/Tools/Scripts /webkit/Tools/Scripts

ENV LD_LIBRARY_PATH=/webkit/WebKitBuild/Debug/lib

WORKDIR /webkit/WebKitBuild/Debug

ENTRYPOINT ["/webkit/Tools/Scripts"]
CMD ["--help"]

LABEL Name=docker-webkit Version=245504
