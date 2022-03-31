FROM ubuntu:18.04

MAINTAINER mislav.novakovic@sartura.hr

RUN \ 
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
      git \
      vim \
      cmake \
      build-essential \
      wget \
      zlib1g-dev \
      supervisor \
      libpcre2-dev \
      pkg-config \
      libavl-dev \
      libev-dev \
      libprotobuf-c-dev \
      protobuf-c-compiler \
      libssl-dev \
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

RUN \
    git clone http://git.libssh.org/projects/libssh.git && \
    cd libssh && \
    git checkout libssh-0.9.6 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr  .. && \
    make install && \
    ldconfig
    

# libyang
RUN \
      cd /opt/dev && \
      git clone -b master https://github.com/CESNET/libyang.git && \
      cd libyang && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# sysrepo
RUN \
      cd /opt/dev && \
      git clone -b master https://github.com/sysrepo/sysrepo.git && \
      cd sysrepo && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_TESTS=OFF -DREPOSITORY_LOC:PATH=/etc/sysrepo .. && \
      make -j2 && \
      make install && \
      ldconfig

# libnetconf2
RUN \
      cd /opt/dev && \
      git clone -b master https://github.com/CESNET/libnetconf2.git && \
      cd libnetconf2 && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# keystore
RUN \
      cd /opt/dev && \
      git clone -b master https://github.com/CESNET/Netopeer2.git && \
      cd Netopeer2 && \
      mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Debug" .. && \
      make -j2 && \
      make install && \
      ldconfig

# netopeer2
#RUN \
#      cd /opt/dev && \
#      cd Netopeer2/server && mkdir build && cd build && \
#      cmake -DCMAKE_BUILD_TYPE:String="Debug" .. && \
#      make -j2 && \
#      make install && \
#      cd ../../cli && mkdir build && cd build && \
#      cmake -DCMAKE_BUILD_TYPE:String="Debug" .. && \
#      make -j2 && \
#      make install

ENV EDITOR vim
EXPOSE 830

COPY supervisord.conf /etc/supervisord.conf
CMD  ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
