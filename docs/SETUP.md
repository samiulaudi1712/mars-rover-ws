# Setup

This workspace runs ROS 2 Humble inside a Docker container (Ubuntu 22.04 base)
on top of an Ubuntu 24.04 host, because Humble does not officially support 24.04.

## Start the environment
```
cd ~/mars-rover-ws
docker compose -f docker/docker-compose.yml up -d
docker exec -it rover_dev bash
```

## Build the workspace (inside the container)
```
cd ~/mars-rover-ws
colcon build --symlink-install
source install/setup.bash
```

## Host hardening applied
- zram (RAM-based swap, no disk cost)
- journald capped at 1G / 2 weeks
- unattended-upgrades auto-reboot disabled
- USB autosuspend disabled via udev rule
- Container has explicit CPU/memory limits, auto-restart, and a health check

See the full setup guide PDF in this repo (or ask Claude) for the complete
explanation of every step and why it's there.
