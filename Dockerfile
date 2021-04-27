ARG UBUNTU_VERSION=18.04
# https://hub.docker.com/r/nvidia/cudagl
ARG ARCH=gl
ARG CUDA=10.2
FROM nvidia/cuda${ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base

LABEL maintainer="Emiliano Borghi"

ARG uid
ENV USER slam

# Setup environment
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV \
  LANG=en_US.UTF-8 \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm

# Dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-transport-https \
        apt-utils \
        bash-completion \
        build-essential \
        ca-certificates \
        cmake \
        eog \
        gdb \
        git \
        gnupg2 \
        libxt-dev \
        mesa-utils \
        nano \
        software-properties-common \
        sudo \
        tmux \
        unzip \
        wget

# Create a user with passwordless sudo
USER root
RUN adduser --gecos "Development User" --disabled-password -u ${uid} $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install third part libraries

# OpenCV 3
RUN apt-get update \
    && apt-get install -y \
        libopencv-dev \
        python3-matplotlib \
        python3-opencv \
        python-pip \
        python3-pip \
        python3-scipy \
        python-tk \
    && ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*
RUN pip2 install \
    matplotlib \
    opencv-contrib-python \
    scikit-build

COPY 3rdparty /3rdparty

# Ceres solver
RUN mkdir -p /3rdparty/ceres-solver/build
WORKDIR /3rdparty/ceres-solver/build
RUN apt-get update && \
    apt-get install -y \
        cmake \
        libatlas-base-dev \
        libeigen3-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libsuitesparse-dev
RUN cmake ..
RUN make -j3
RUN make install
RUN ldconfig

# DBoW3
RUN mkdir -p /3rdparty/DBoW3/build
WORKDIR /3rdparty/DBoW3/build
RUN cmake ..
RUN make -j3
RUN make install
RUN ldconfig

# Pangolin
RUN apt-get update && \
    apt-get install -y \
        cmake \
        libglew-dev \
        libpython2.7-dev
RUN pip3 install \
    numpy \
    pyopengl \
    Pillow \
    pybind11
RUN mkdir -p /3rdparty/Pangolin/build
WORKDIR /3rdparty/Pangolin/build
RUN cmake ..
RUN make -j3
RUN make install
RUN ldconfig

# Sophus
RUN mkdir -p /3rdparty/Sophus/build
WORKDIR /3rdparty/Sophus/build
RUN cmake ..
RUN make -j3
RUN make install
RUN ldconfig

# g2o
RUN apt-get update && \
    apt-get install -y \
        libqglviewer-dev-qt5 \
        libsuitesparse-dev \
        qt5-qmake \
        qtdeclarative5-dev
RUN mkdir -p /3rdparty/g2o/build
WORKDIR /3rdparty/g2o/build
RUN cmake ..
RUN make -j3
RUN make install
RUN ldconfig

# GTest
RUN apt-get update && \
    apt-get install -y \
        libgtest-dev
RUN mkdir -p /usr/src/googletest/googletest/build
WORKDIR /usr/src/googletest/googletest/build
RUN cmake ..
RUN make
RUN cp libgtest* /usr/lib/
RUN mkdir /usr/local/lib/googletest
RUN ln -s /usr/lib/libgtest.a /usr/local/lib/googletest/libgtest.a
RUN ln -s /usr/lib/libgtest_main.a /usr/local/lib/googletest/libgtest_main.a

# Install ROS Melodic
# Setup sources.list for ROS
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list
# Setup keys for ROS
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
# Install bootstrap tools
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        python-rosdep \
        python-rosinstall
# Install ROS packages
RUN apt-get update \
    && apt-get install -y \
        ros-melodic-octomap-ros \
        ros-melodic-ros-base
# Initialize rosdep
RUN rosdep init
USER $USER
RUN rosdep update
# Automatically source ROS workspace
RUN echo ". /opt/ros/melodic/setup.bash" >> /home/${USER}/.bashrc
ENV WS_DIR "/catkin_ws"
ENV CATKIN_SETUP_BASH "${WS_DIR}/devel/setup.bash"
RUN echo "[[ -f ${CATKIN_SETUP_BASH} ]] && . ${CATKIN_SETUP_BASH}" >> /home/${USER}/.bashrc

# Compile exercises
USER root
RUN apt-get update && \
    apt-get install -y \
        freeglut3-dev \
        libpcl-dev \
        octomap-tools

USER ${USER}
WORKDIR /exercises
COPY entrypoint.sh /entrypoint.sh
CMD [ "/entrypoint.sh" ]
