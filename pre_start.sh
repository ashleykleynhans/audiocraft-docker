#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au /venv/ /workspace/venv/

# Sync Audiocraft Plus to workspace to support Network volumes
echo "Syncing Audiocraft Plus to workspace, please wait..."
rsync -au /audiocraft/ /workspace/audiocraft/

# Fix the venv to make it work from /workspace
echo "Fixing venv..."
/fix_venv.sh /venv /workspace/venv

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/audiocraft_plus"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   ./python3 app.py --listen 0.0.0.0 --server_port 3001"
else
    mkdir -p /workspace/logs
    echo "Starting Audiocraft Plus"
    export HF_HOME="/workspace"
    source /workspace/venv/bin/activate
    cd /workspace/audiocraft_plus && nohup python3 app.py --listen 0.0.0.0 --server_port 3001 > /workspace/logs/audiocraft.log 2>&1 &
    echo "Audiocraft Plus started"
    echo "Log file: /workspace/logs/audiocraft.log"
    deactivate
fi

echo "All services have been started"