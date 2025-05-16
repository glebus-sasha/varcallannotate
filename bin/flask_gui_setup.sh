#!/bin/bash
# =======================
# Flask GUI setup
# =======================

flask_create_env() {
  echo "Создаем conda окружение '$MAMBA_ENV' с Flask и Flask-SocketIO..."
  if ! check_mamba_installed; then
    echo -e "${red}Ошибка:${reset} Mamba не установлена. Установите Mamba перед созданием окружения."
    return 1
  fi

  source "$CONDA_DIR/etc/profile.d/conda.sh"

  if conda env list | grep -qE "^$MAMBA_ENV\s"; then
    echo_status 0 "Окружение '$MAMBA_ENV' уже существует"
  else
    mamba create -y -n "$MAMBA_ENV" flask flask-socketio
    echo_status $? "Окружение '$MAMBA_ENV' создано"
  fi
}

flask_create_folders_and_config() {
mkdir -p "$WORK_DIR"
mkdir -p "$WORK_DIR/tmp_reads"
mkdir -p "$WORK_DIR/tmp_output"
cat > "./path_config.py" <<EOF
READS_FOLDER    = "$WORK_DIR/tmp_reads"
OUTPUT_FOLDER   = "$WORK_DIR/tmp_output"
REFERENCE_FOLDER = "$REF_DIR/hg38"
FAIDX_FOLDER    = "$REF_DIR/faidx"
BWAIDX_FOLDER   = "$REF_DIR/bwaidx"
VEP_CACHE_DIR   = "$VEP_CACHE_DIR"
BED_DIR         = "$PWD/bed"


nextflow_command = ["nextflow", "run",
    ".", "-profile", "apptainer",
    "--reads", READS_FOLDER,
    "--outdir", OUTPUT_FOLDER,
    "--reference", REFERENCE_FOLDER,
    "--faidx", FAIDX_FOLDER,
    "--bwaidx", BWAIDX_FOLDER,
    "--vep_cache", VEP_CACHE_DIR,
    "--bed", BED_DIR,
    "--reports"]
EOF
  echo_status $? "Конфигурационный файл path_config.py"
}

test_nextflow_profile() {
  if ! check_nextflow_installed; then
    echo -e "${red}Ошибка:${reset} Nextflow не установлен."
    return 1
  fi

  echo "Выполняется тестовый запуск nextflow run -profile test,apptainer ..."
  nextflow run . -profile test,apptainer --vep_cache $VEP_CACHE_DIR -resume
  echo_status $? "Тестовый запуск Nextflow завершен"
}

run_flask_gui() {
  if ! check_flask_installed || ! check_flask_config_exists; then
    echo -e "${red}Ошибка:${reset} Flask GUI не установлена или не настроена. Сначала выполните установку."
    return 1
  fi

  source "$CONDA_DIR/etc/profile.d/conda.sh"
  conda activate "$MAMBA_ENV"
  echo "Запускаем Flask сервер..."
  python3 server.py path_config.py
}