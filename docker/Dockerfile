FROM almalinux:9

RUN dnf update -y && \
    dnf install -y \
    ncurses \
    iproute \
    psmisc \
    procps-ng \
    bind-utils \
    nmap-ncat \
    util-linux \
    man-db \
    vim \
    tree \
    iptables \
    nftables \
    tcpdump \
    wireshark \
    java-17-openjdk-devel \
    iputils && \
    dnf clean all

CMD ["/bin/bash"]

#docker build -t my-custom-linux .      
#docker run -it --privileged my-custom-linux
