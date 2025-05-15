#!/bin/bash

JAVA_VERSION="17.0.10-tem"
GOVERSION="1.23.4"
GO_ARCH="amd64"
GO_OS="linux"
APPTAINER_REPO="https://github.com/apptainer/apptainer.git"
INSTALL_DIR="$HOME/.local/bin"
CONDA_DIR="$HOME/miniconda3"
MAMBA_ENV="flask_gui"
VEP_CACHE_DIR="$BASE_DIR/.vep"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

echo_status() {
  if [ "$1" -eq 0 ]; then
    echo -e "${green}✔${reset} $2"
  else
    echo -e "${red}✘${reset} $2"
  fi
}

# =======================
# Checks
# =======================

check_java_installed() {
  # Проверяем версию Java и что это Temurin
  java -version 2>&1 | grep -q "17\.0\.10" && java -version 2>&1 | grep -qi "temurin"
}

check_nextflow_installed() {
  command -v nextflow &>/dev/null
}

check_apptainer_installed() {
  command -v apptainer &>/dev/null
}

check_mamba_installed() {
  [ -x "$CONDA_DIR/bin/mamba" ]
}

check_flask_installed() {
  if ! check_mamba_installed; then return 1; fi
  # Активируем окружение и проверяем наличие flask и flask-socketio
  source "$CONDA_DIR/etc/profile.d/conda.sh"
  conda activate "$MAMBA_ENV" &>/dev/null || return 1
  mamba list flask | grep -q "flask" && mamba list flask-socketio | grep -q "flask-socketio"
}

check_flask_config_exists() {
  [ -f "$HOME/varcallannotate/path_config.py" ]
}

check_vep_cache_installed() {
  [ -d "$VEP_CACHE_DIR/homo_sapiens_vep_114_GRCh38" ]
}

# =======================
# Installers
# =======================

install_java() {
  if check_java_installed; then
    echo_status 0 "Java $JAVA_VERSION уже установлена"
    return 0
  fi
  echo "Устанавливаем SDKMAN и Java $JAVA_VERSION..."
  curl -s https://get.sdkman.io | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java "$JAVA_VERSION"
  echo_status $? "Установка Java завершена"
}

install_nextflow() {
  if check_nextflow_installed; then
    echo_status 0 "Nextflow уже установлен"
    return 0
  fi
  echo "Устанавливаем Nextflow..."
  curl -s https://get.nextflow.io | bash
  chmod +x nextflow
  mkdir -p "$INSTALL_DIR"
  mv nextflow "$INSTALL_DIR/"

  # Добавляем в .bashrc, если отсутствует
  grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

  # Используем функцию для экспорта переменных Nextflow кэширования, избегая дублирования
  add_or_replace_bashrc_line 'export NXF_APPTAINER_CACHEDIR="$HOME/.nextflow/apptainer"'
  add_or_replace_bashrc_line 'export NXF_SINGULARITY_CACHEDIR="$HOME/.nextflow/singularity"'

  # Для применения переменных сразу
  export PATH="$HOME/.local/bin:$PATH"
  export NXF_APPTAINER_CACHEDIR="$HOME/.nextflow/apptainer"
  export NXF_SINGULARITY_CACHEDIR="$HOME/.nextflow/singularity"

  echo_status $? "Установка Nextflow завершена"
}

# Функция для замены или добавления строки в .bashrc (если существует, заменяем, иначе добавляем)
add_or_replace_bashrc_line() {
  local line="$1"
  local file="$HOME/.bashrc"
  local key="${line%%=*}"  # Получаем часть до знака '='
  # Экранируем для grep
  local grep_key=$(echo "$key" | sed 's/\$/\\$/g')
  if grep -q "^$grep_key" "$file"; then
    # Заменяем строку
    sed -i "s|^$grep_key.*|$line|" "$file"
  else
    echo "$line" >> "$file"
  fi
}

install_apptainer() {
  if check_apptainer_installed; then
    echo_status 0 "Apptainer уже установлен"
    return 0
  fi
  echo "Устанавливаем Apptainer..."
  sudo apt-get update
  sudo apt-get install -y build-essential libseccomp-dev pkg-config uidmap squashfs-tools fakeroot cryptsetup tzdata dh-apparmor curl wget git libsubid-dev

  wget -O /tmp/go${GOVERSION}.${GO_OS}-${GO_ARCH}.tar.gz https://dl.google.com/go/go${GOVERSION}.${GO_OS}-${GO_ARCH}.tar.gz
  sudo tar -C /usr/local -xzf /tmp/go${GOVERSION}.${GO_OS}-${GO_ARCH}.tar.gz

  add_or_replace_bashrc_line 'export PATH=$PATH:/usr/local/go/bin'
  export PATH=$PATH:/usr/local/go/bin

  if [ ! -d "$HOME/apptainer" ]; then
    git clone "$APPTAINER_REPO" "$HOME/apptainer"
  fi

  cd "$HOME/apptainer" || { echo "Ошибка: не удалось перейти в каталог apptainer"; return 1; }
  ./mconfig
  cd ./builddir || { echo "Ошибка: не удалось перейти в builddir"; return 1; }
  make
  sudo make install
  cd ~
  echo_status $? "Установка Apptainer завершена"
}

install_mamba() {
  if check_mamba_installed; then
    echo_status 0 "Mamba уже установлена"
    return 0
  fi
  echo "Устанавливаем Mamba (Miniconda3)..."
  wget -O ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash ~/miniconda.sh -b -p "$CONDA_DIR"
  rm ~/miniconda.sh
  export PATH="$CONDA_DIR/bin:$PATH"
  eval "$($CONDA_DIR/bin/conda shell.bash hook)"
  conda init
  conda install -y -n base -c conda-forge mamba
  echo_status $? "Установка Mamba завершена"
}

install_vep_cache() {
  # Проверяем и запрашиваем BASE_DIR, если не задана
  if [ -z "$BASE_DIR" ]; then
    echo "Переменная BASE_DIR не задана."
    read -rp "Пожалуйста, укажите путь к BASE_DIR (например, /path/to/project): " input_dir
    while [ -z "$input_dir" ]; do
      echo "Путь не может быть пустым."
      read -rp "Пожалуйста, укажите путь к BASE_DIR: " input_dir
    done
    export BASE_DIR="$input_dir"
  else
    echo "Используется существующая переменная BASE_DIR=$BASE_DIR"
  fi

  # Определяем и экспортируем VEP_CACHE_DIR
  export VEP_CACHE_DIR="$BASE_DIR/vep_cache"

  # Проверяем, есть ли кэш, если нет — скачиваем
  if [ ! -d "$VEP_CACHE_DIR" ]; then
    echo "Кэш VEP не найден в $VEP_CACHE_DIR, загружаю..."
    mkdir -p "$VEP_CACHE_DIR"
    # Здесь укажи свою ссылку на кэш VEP
    curl -L -o "$VEP_CACHE_DIR/vep_cache.tar.gz" "https://ftp.ensembl.org/pub/release-114/variation/indexed_vep_cache/homo_sapiens_vep_114_GRCh38.tar.gz"
    tar -xzvf "$VEP_CACHE_DIR/vep_cache.tar.gz" -C "$VEP_CACHE_DIR"
    rm "$VEP_CACHE_DIR/vep_cache.tar.gz"
  else
    echo "Кэш VEP уже есть в $VEP_CACHE_DIR"
  fi
}


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
  conda activate base

  if conda env list | grep -qE "^$MAMBA_ENV\s"; then
    echo_status 0 "Окружение '$MAMBA_ENV' уже существует"
  else
    mamba create -y -n "$MAMBA_ENV" flask flask-socketio
    echo_status $? "Окружение '$MAMBA_ENV' создано"
  fi
}

flask_create_folders_and_config() {
  echo -n "Введите абсолютный путь к корневой папке (например, /home/username/): "
  read -r BASE_DIR
  # Убираем кавычки, если они есть
  BASE_DIR="${BASE_DIR%\"}"
  BASE_DIR="${BASE_DIR#\"}"

  mkdir -p "$BASE_DIR/tmp_reads" "$BASE_DIR/tmp_output"

  mkdir -p "$HOME/varcallannotate"
  cat > "$HOME/varcallannotate/path_config.py" <<EOF
READS_FOLDER = "$BASE_DIR/tmp_reads"
OUTPUT_FOLDER = "$BASE_DIR/tmp_output"
nextflow_path = "$BASE_DIR/varcallannotate"

nextflow_command = ["nextflow", "run",
    ".", "-profile", "apptainer",
    "--reads", READS_FOLDER,
    "--outdir", OUTPUT_FOLDER,
    "--reports"]
EOF
  echo_status $? "Конфигурационный файл path_config.py создан в ~/varcallannotate"
}

test_nextflow_profile() {
  if ! check_nextflow_installed; then
    echo -e "${red}Ошибка:${reset} Nextflow не установлен."
    return 1
  fi

  echo "Выполняется тестовый запуск nextflow run -profile test,apptainer ..."
  nextflow run . -profile test,apptainer --vep_cache $BASE_DIR/vep_cache
  echo_status $? "Тестовый запуск Nextflow завершен"
}

run_flask_gui() {
  if ! check_flask_installed || ! check_flask_config_exists; then
    echo -e "${red}Ошибка:${reset} Flask GUI не установлена или не настроена. Сначала выполните установку (пункты 5 и 6)."
    return 1
  fi

  source "$CONDA_DIR/etc/profile.d/conda.sh"
  conda activate "$MAMBA_ENV"
  echo "Запускаем Flask сервер..."
  cd "$HOME/varcallannotate" || return 1
  python3 server.py path_config.py
}

# =======================
# Меню
# =======================

print_menu() {
  check_java_installed; JAVA_STATUS=$?
  check_nextflow_installed; NF_STATUS=$?
  check_apptainer_installed; APP_STATUS=$?
  check_mamba_installed; MAMBA_STATUS=$?
  check_flask_installed; FLASK_STATUS=$?
  check_flask_config_exists; CONFIG_STATUS=$?
  check_vep_cache_installed; VEP_CACHE_STATUS=$?

  echo
  echo "=========== МЕНЮ УСТАНОВКИ ==========="
  echo -n "1) Установить Java ($JAVA_VERSION)        ["; [ $JAVA_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo -n "2) Установить Nextflow                    ["; [ $NF_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo -n "3) Установить Apptainer                   ["; [ $APP_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo -n "4) Установить Mamba                       ["; [ $MAMBA_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo -n "5) Создать conda окружение Flask GUI      ["; [ $FLASK_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo -n "6) Создать папки и конфиг для Flask GUI   ["; [ $CONFIG_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"; echo -e "${reset}]"
  echo    "7) Тестовый запуск nextflow с профилями test,apptainer"
  echo    "8) Запустить Flask GUI"
  echo    "9) Установить всё (1-6)"
  echo -n "10) Установить VEP cache                  ["
[ $VEP_CACHE_STATUS -eq 0 ] && echo -n "${green}✔" || echo -n "${red}✘"
echo -e "${reset}]"
  echo    "0) Выход"
  echo "======================================="
}

while true; do
  print_menu
  read -r choice
  case $choice in
    1) install_java ;;
    2) install_nextflow ;;
    3) install_apptainer ;;
    4) install_mamba ;;
    5) flask_create_env ;;
    6) flask_create_folders_and_config ;;
    7) test_nextflow_profile ;;
    8) run_flask_gui ;;
    9)
       install_java
       install_nextflow
       install_apptainer
       install_mamba
       flask_create_env
       flask_create_folders_and_config
       install_vep_cache
       ;;
    10) install_vep_cache ;;
    0) echo "Выход."; exit 0 ;;
    *) echo "Неверный ввод, попробуйте еще раз." ;;
  esac
done
