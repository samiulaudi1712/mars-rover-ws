# ADR 0001: Run ROS 2 Humble in Docker on Ubuntu 24.04

## Context
ROS 2 Humble's binary packages officially target Ubuntu 22.04 only.
The team workstation runs Ubuntu 24.04.

## Decision
Run Humble inside a Docker container built on an Ubuntu 22.04 base image
(osrf/ros:humble-desktop-full), rather than installing Humble directly on
the host or upgrading the whole team to ROS 2 Jazzy.

## Consequences
- Host OS stays untouched and stable regardless of ROS distro requirements.
- A crash inside the container cannot take down the host.
- Requires Docker knowledge for day-to-day development.
- GUI tools (RViz, Gazebo) require X11 passthrough configuration.
