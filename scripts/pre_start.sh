#!/usr/bin/env bash

export PYTHONUNBUFFERED=1

echo "Template version: ${TEMPLATE_VERSION}"
echo "venv: ${VENV_PATH}"

DOCKER_IMAGE_VERSION_FILE="/workspace/audiocraft_plus/docker_image_version"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync venv to workspace to support Network volumes
        echo "Syncing venv to workspace, please wait..."
        mkdir -p ${VENV_PATH}
        mv /venv/* ${VENV_PATH}/
        rm -rf /venv

        # Sync Audiocraft Plus to workspace to support Network volumes
        echo "Syncing Audiocraft Plus to workspace, please wait..."
        mv /${APP} /workspace/${APP}

        echo "${TEMPLATE_VERSION}" > ${DOCKER_IMAGE_VERSION_FILE}
    fi
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
