FROM osrf/ros:humble-desktop-full

RUN apt-get update && apt-get install -y \
    python3-pip python3-colcon-common-extensions python3-rosdep \
    python3-vcstool git nano vim tmux net-tools iputils-ping \
    ros-humble-xacro ros-humble-robot-state-publisher \
    ros-humble-ros2-control ros-humble-ros2-controllers \
    ros-humble-gazebo-ros-pkgs ros-humble-navigation2 ros-humble-nav2-bringup \
    ros-humble-rosbridge-suite ros-humble-foxglove-bridge \
    ros-humble-rqt* ros-humble-rviz2 \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=rover
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -aG dialout,plugdev $USERNAME

USER $USERNAME
WORKDIR /home/rover/mars-rover-ws

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc \
    && echo "if [ -f /home/rover/mars-rover-ws/install/setup.bash ]; then source /home/rover/mars-rover-ws/install/setup.bash; fi" >> ~/.bashrc

CMD ["bash"]
