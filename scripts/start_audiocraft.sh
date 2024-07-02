#!/usr/bin/env bash

echo "Starting Audiocraft Plus"
export HF_HOME="/workspace"
export PYTHONUNBUFFERED=1
source /venv/bin/activate
cd /workspace/audiocraft_plus
nohup python3 app.py --listen 0.0.0.0 --server_port 3001 > /workspace/logs/audiocraft.log 2>&1 &
echo "Audiocraft Plus started"
echo "Log file: /workspace/logs/audiocraft.log"
deactivate
