variable "APP" {
    default = "audiocraft"
}

variable "RELEASE" {
    default = "3.0.9"
}

variable "CU_VERSION" {
    default = "118"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["ashleykza/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "2.2.0+cu${CU_VERSION}"
        XFORMERS_VERSION = "0.0.24+cu${CU_VERSION}"
        AUDIOCRAFT_VERSION = "2.0.1"
        RUNPODCTL_VERSION = "v1.14.2"
        VENV_PATH = "/workspace/venvs/audiocraft_plus"
    }
}
