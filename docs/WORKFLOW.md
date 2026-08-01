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
