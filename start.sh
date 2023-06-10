#!/usr/bin/env bash
export VENV=/workspace/venv
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au --remove-source-files /venv/ /workspace/venv/
rm -rf /venv

# Sync audiocraft to workspace to support Network volumes
echo "Syncing audiocraft to workspace, please wait..."
rsync -au --remove-source-files /audiocraft/ /workspace/audiocraft/
rm -rf /audiocraft

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys
    chmod 700 -R ~/.ssh
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    source ${VENV}/bin/activate
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
    deactivate
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/audiocraft"
    echo "   deactivate && source /workspace/venv/activate"
    echo "   ./python3 app.py"
else
    mkdir -p /workspace/logs
    echo "Starting audiocraft"
    source ${VENV}/bin/activate
    cd /workspace/audiocraft && nohup python3 app.py > /workspace/logs/audiocraft.log &
    echo "audiocraft started"
    echo "Log file: /workspace/logs/audiocraft.log"
    deactivate
fi

echo "All services have been started"

sleep infinity