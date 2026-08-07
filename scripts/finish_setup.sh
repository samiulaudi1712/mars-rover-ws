#!/usr/bin/env bash
# ==============================================================================
# Team MongolTori — Mars Rover Workstation Finisher
# Completes: host hardening, terminal branding, and documentation scaffold.
# Safe to re-run — every step below either checks first or simply overwrites
# its own file with the same content, so running this twice does no harm.
#
# BEFORE RUNNING:
#   1. Download MT_logo.png from the chat and leave it in ~/Downloads/
#   2. Make sure you are on your HOST prompt (dark_knight@DarkKnight), not
#      inside the rover_dev container.
#
# RUN WITH:
#   bash finish_setup.sh
# ==============================================================================

set -uo pipefail   # catch unset vars and pipe failures; deliberately NOT -e,
                    # so one skippable issue (like a missing logo file) doesn't
                    # abort everything else below it.

echo ""
echo "=========================================="
echo " PART A — Host Stability Hardening"
echo "=========================================="

echo "--- A1: base tools ---"
sudo apt update
sudo apt install -y htop tree ncdu

echo "--- A2: zram (RAM-based swap, costs no disk space) ---"
sudo apt install -y systemd-zram-generator
echo -e "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd" | sudo tee /etc/systemd/zram-generator.conf > /dev/null
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
zramctl

echo "--- A3: cap journald logs so they can't fill the disk ---"
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=1G\nMaxRetentionSec=2week" | sudo tee /etc/systemd/journald.conf.d/size-limit.conf > /dev/null
sudo systemctl restart systemd-journald
journalctl --disk-usage

echo "--- A4: disable unattended-upgrades auto-reboot ---"
if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
    sudo sed -i 's/Unattended-Upgrade::Automatic-Reboot "true"/Unattended-Upgrade::Automatic-Reboot "false"/' /etc/apt/apt.conf.d/50unattended-upgrades
    grep "Automatic-Reboot" /etc/apt/apt.conf.d/50unattended-upgrades || echo "(no Automatic-Reboot line found — was already off by default)"
fi
sudo systemctl disable --now unattended-upgrades.service 2>/dev/null || echo "(unattended-upgrades service was already inactive)"

echo "--- A5: stop USB devices (sensors, motor controllers) from auto-suspending ---"
echo 'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"' | sudo tee /etc/udev/rules.d/50-usb-no-autosuspend.rules > /dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger
cat /etc/udev/rules.d/50-usb-no-autosuspend.rules

echo ""
echo "=========================================="
echo " PART B — Branded Terminal (Team MongolTori)"
echo "=========================================="

echo "--- B1: install kitty + chafa ---"
sudo apt install -y kitty chafa

echo "--- B2: place the logo ---"
mkdir -p ~/.config/mongoltori
if [ -f ~/Downloads/MT_logo.png ]; then
    mv ~/Downloads/MT_logo.png ~/.config/mongoltori/MT_logo.png
    echo "Logo moved into place."
elif [ -f ~/.config/mongoltori/MT_logo.png ]; then
    echo "Logo already in place, skipping."
else
    echo "WARNING: ~/Downloads/MT_logo.png not found. Download it from the chat"
    echo "and re-run this script, or manually run:"
    echo "  mv ~/Downloads/MT_logo.png ~/.config/mongoltori/MT_logo.png"
fi

echo "--- B3: banner script ---"
cat > ~/.config/mongoltori/banner.sh << 'EOF'
#!/usr/bin/env bash
LOGO="$HOME/.config/mongoltori/MT_logo.png"
if command -v chafa >/dev/null 2>&1 && [ -f "$LOGO" ]; then
    chafa --size=28x14 --symbols=block "$LOGO" 2>/dev/null
fi
printf "\n"
printf "\033[1;38;5;208m  Samiul Islam Audi\033[0m\n"
printf "\033[38;5;203m  Controls and Software Engineer\033[0m\n"
printf "\033[38;5;208m  BRACU CSE || Team MongolTori\033[0m\n\n"
EOF
chmod +x ~/.config/mongoltori/banner.sh

echo "--- B4: wire the banner into new interactive terminals ---"
if ! grep -q "MongolTori terminal identity banner" ~/.bashrc 2>/dev/null; then
cat >> ~/.bashrc << 'EOF'

# --- Team MongolTori terminal identity banner ---
case $- in
    *i*) ;;
    *) return ;;
esac
if [ -t 1 ] && [ -z "$MONGOLTORI_BANNER_SHOWN" ] && [ -f "$HOME/.config/mongoltori/banner.sh" ]; then
    export MONGOLTORI_BANNER_SHOWN=1
    bash "$HOME/.config/mongoltori/banner.sh"
fi
EOF
    echo "Banner hook added to ~/.bashrc."
else
    echo "Banner hook already present in ~/.bashrc, skipping."
fi

echo "--- B5: register kitty as the default terminal ---"
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50
echo "Run 'sudo update-alternatives --config x-terminal-emulator' manually to SELECT kitty from the menu (interactive step, not automated here)."

echo "--- B6: autostart kitty at login ---"
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/mongoltori-terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=MongolTori Terminal
Exec=kitty
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

echo ""
echo "=========================================="
echo " PART C — Documentation Scaffold"
echo "=========================================="

cd ~/mars-rover-ws || { echo "ERROR: ~/mars-rover-ws not found. Skipping Part C."; exit 1; }
mkdir -p docs/ADRs docs/subsystems

cat > docs/SETUP.md << 'EOF'
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
EOF

cat > docs/WORKFLOW.md << 'EOF'
# Daily Workflow

## Git
```
git pull origin main
git checkout -b feature/<short-task-name>
# ... work ...
git add .
git commit -m "control: <describe the change>"
git push -u origin feature/<short-task-name>
```

Commit prefixes: control: | sim: | nav: | hw: | docs: | ci:

## Before any hardware test
1. Record only the topics you need:
   ros2 bag record /cmd_vel /odom /imu/data /battery_state -o bags/test_$(date +%F_%H%M)
2. Use tmux so a dropped terminal doesn't kill the test: tmux new -s rover_test
3. Check disk headroom first: df -h ~
4. Confirm the container is healthy: docker ps

## Weekly maintenance
docker system prune -f
du -sh ~/mars-rover-ws/bags/*
df -h ~
EOF

cat > docs/ADRs/0001-use-docker-for-ros2-humble.md << 'EOF'
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
EOF

touch docs/subsystems/.gitkeep

echo "Documentation scaffold created under docs/."

echo ""
echo "=========================================="
echo " PART D — Commit and push the docs"
echo "=========================================="
git add docs/
git commit -m "docs: add setup guide, workflow, and first ADR" || echo "(nothing new to commit)"
git push

echo ""
echo "=========================================="
echo " PART E — Final Verification"
echo "=========================================="
echo "--- Docker container ---"
docker ps
echo "--- zram ---"
zramctl
echo "--- journald cap ---"
journalctl --disk-usage
echo "--- unattended-upgrades status ---"
systemctl is-active unattended-upgrades
echo "--- USB udev rule ---"
ls -la /etc/udev/rules.d/50-usb-no-autosuspend.rules
echo "--- Git log ---"
git log --oneline
echo "--- Docs created ---"
ls -la docs/ docs/ADRs/

echo ""
echo "=========================================="
echo " DONE. Open a NEW terminal now to see the"
echo " Team MongolTori banner, and manually run:"
echo "   sudo update-alternatives --config x-terminal-emulator"
echo " to select kitty as your default terminal."
echo "=========================================="
