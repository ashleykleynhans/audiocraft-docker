#!/usr/bin/env bash

export PYTHONUNBUFFERED=1

echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e "/workspace/audiocraft_plus/template_version" ]]; then
    EXISTING_VERSION=$(cat /workspace/audiocraft_plus/template_version)
else
    EXISTING_VERSION="0.0.0"
fi

sync_apps() {
    # Sync venv to workspace to support Network volumes
    echo "Syncing venv to workspace, please wait..."
    mkdir -p ${VENV_PATH}
    rsync --remove-source-files -rlptDu /venv/ ${VENV_PATH}/

    # Sync Audiocraft Plus to workspace to support Network volumes
    echo "Syncing Audiocraft Plus to workspace, please wait..."
    rsync --remove-source-files -rlptDu /audiocraft_plus/ /workspace/audiocraft_plus/

    echo "${TEMPLATE_VERSION}" > /workspace/audiocraft_plus/template_version
}

fix_venvs() {
    # Fix the venv to make it work from /workspace
    echo "Fixing venv..."
    /fix_venv.sh /venv ${VENV_PATH}
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/audiocraft_plus"
    echo "   deactivate && source ${VENV_PATH}/bin/activate"
    echo "   ./python3 app.py --listen 0.0.0.0 --server_port 3001"
else
    echo "Starting Audiocraft Plus"
    export HF_HOME="/workspace"
    source ${VENV_PATH}/bin/activate
    cd /workspace/audiocraft_plus && nohup python3 app.py --listen 0.0.0.0 --server_port 3001 > /workspace/logs/audiocraft.log 2>&1 &
    echo "Audiocraft Plus started"
    echo "Log file: /workspace/logs/audiocraft.log"
    deactivate
fi

echo "All services have been started"
