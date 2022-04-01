FROM ubuntu:20.04

MAINTAINER macauleycheng@gmail.com

RUN \ 
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
      git \
      vim \
      bison \
      autoconf \
      dh-autoreconf\
      flex \
      cmake \
      build-essential \
      zlib1g-dev \
      supervisor \
      libpcre3-dev \
      pkg-config \
      libavl-dev \
      libev-dev \
      libgcrypt20-dev \
      libssh-dev \
      libprotobuf-c-dev \
      protobuf-c-compiler \
      libssl-dev \
      libcjson-dev \
      libxml2-dev \
      libnl-3-dev \
      libnl-genl-3-dev \
      libnl-route-3-dev \
      libnl-nf-3-dev \
      swig \
      python-dev

# add netconf user
RUN \
    adduser --system netconf && \
    echo "netconf:netconf" | chpasswd

# generate ssh keys for netconf user
RUN \
    mkdir -p /home/netconf/.ssh && \
    ssh-keygen -A && \
    ssh-keygen -t dsa -P '' -f /home/netconf/.ssh/id_dsa && \
    cat /home/netconf/.ssh/id_dsa.pub > /home/netconf/.ssh/authorized_keys

# use /opt/dev as working directory
RUN mkdir /opt/dev
WORKDIR /opt/dev


# libyang
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libyang.git && \
      cd libyang && git checkout v1.0-r4 && mkdir build && cd build && \
      cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# sysrepo
RUN \
      cd /opt/dev && \
      git clone https://github.com/sysrepo/sysrepo.git && \
      cd sysrepo && git checkout v0.7.8 && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_TESTS=OFF -DREPOSITORY_LOC:PATH=/etc/sysrepo .. && \
      make -j2 && \
      make install && \
      ldconfig

# libnetconf2
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libnetconf2.git && \
      cd libnetconf2 && git checkout v0.12-r2 && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && \
      make -j2 && \
      make install && \
      ldconfig

RUN \
      cd /opt/dev && \
      git clone https://github.com/protocolbuffers/protobuf.git && \
      cd protobuf && \
      git submodule update --init --recursive && \
      ./autogen.sh && \
      ./configure && \
      make && \
      make install && \
      ldconfig


RUN \
      cd /opt/dev && \
      git clone  https://github.com/CESNET/Netopeer2.git && \
      cd Netopeer2/cli && git checkout v0.7-r2 && \
      cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr . && \
      make && \
      make install

RUN \
    cd /opt/dev && \
    git clone https://github.com/nocsysmars/tsn.git && \
    cd tsn && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make


ENV EDITOR vim
EXPOSE 830

COPY supervisord.conf /etc/supervisord.conf
CMD  ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
