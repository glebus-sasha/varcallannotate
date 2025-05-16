#!/bin/bash

# =======================
# Checks
# =======================

check_java_installed() {
  command -v java &>/dev/null
}

check_conda_installed() {
  command -v conda &>/dev/null
}

check_mamba_installed() {
  command -v mamba &>/dev/null
}

check_nextflow_installed() {
  command -v nextflow &>/dev/null
}

check_apptainer_installed() {
  command -v apptainer &>/dev/null
}

check_flask_env_exists() {
  # Проверяем, что conda/mamba установлен
  if [[ $MAMBA_STATUS -ne 0 ]]; then
    return 1
  fi

  # Инициализируем conda
  source "$CONDA_DIR/etc/profile.d/conda.sh"

  # Проверяем наличие окружения
  conda env list | grep -qE "^$MAMBA_ENV\s"
}

check_flask_installed() {
  # Проверяем, что conda/mamba установлен
  if [[ $MAMBA_STATUS -ne 0 ]]; then
    return 1
  fi

  source "$CONDA_DIR/etc/profile.d/conda.sh"

  if ! check_flask_env_exists; then
    return 1
  fi

  conda activate "$MAMBA_ENV" &>/dev/null || return 1

  # Проверяем, что flask и flask-socketio установлены в окружении
  conda list flask | grep -q "^flask\s" && conda list flask-socketio | grep -q "^flask-socketio\s"
}

check_flask_config_exists() {
  [ -f "./path_config.py" ]
}

check_vep_cache_installed() {
  [ -d "$VEP_CACHE_DIR" ]
}

check_reference_installed() {
  [ -d "$REF_DIR" ]
}