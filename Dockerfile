FROM ubuntu:bionic as downloader

RUN apt-get update && apt-get install -y curl wget
WORKDIR /tmp
# RUN curl https://s3-us-west-2.amazonaws.com/archives.webkit.org/WebKit-SVN-source.tar.bz2 | tar jxvf
RUN wget --progress=bar:force https://s3-us-west-2.amazonaws.com/archives.webkit.org/WebKit-SVN-source.tar.bz2
RUN tar jxvf WebKit-SVN-source.tar.bz2

####################################################################################################
# FROM ubuntu:bionic as cloner

# RUN apt-get update && apt-get install -y git-core git-svn
# RUN git clone git://git.webkit.org/WebKit.git /WebKit

####################################################################################################
FROM ubuntu:bionic as builder

COPY --from=downloader /tmp/webkit /WebKit

WORKDIR /WebKit

RUN apt-get update && apt-get install -y subversion git-core git-svn cmake build-essential python libicu-dev libxml-libxml-perl ninja-build ruby gperf bison flex

# RUN svn switch --relocate http://svn.webkit.org/repository/webkit/trunk https://svn.webkit.org/repository/webkit/trunk
RUN Tools/Scripts/update-webkit
# RUN Tools/Scripts/webkit-patch setup-git-clone
RUN DEBIAN_FRONTEND=noninteractive Tools/gtk/install-dependencies
# RUN DEBIAN_FRONTEND=noninteractive Tools/Scripts/update-webkitgtk-libs
RUN Tools/Scripts/set-webkit-configuration --debug
RUN Tools/Scripts/build-webkit --gtk --cmakeargs="-GNinja -DENABLE_STATIC_JSC=ON -DUSE_THIN_ARCHIVES=OFF" MiniBrowser

####################################################################################################
FROM ubuntu:bionic

LABEL maintainer "https://github.com/blacktop"

RUN apt-get update && apt-get install -y bubblewrap \
  && echo "===> Clean up unnecessary files..." \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=builder /WebKit/WebKitBuild/Debug/bin /WebKit/bin

WORKDIR /WebKit

ENV LD_LIBRARY_PATH=/WebKit/WebKitBuild/DependenciesGTK/Root/lib

ENTRYPOINT ["Tools/Scripts/run-minibrowser"]
CMD ["--help"]

LABEL Name=docker-webkit Version=0.0.1
