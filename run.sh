#!/bin/bash

source "$(dirname "$0")/bin/check.sh"
source "$(dirname "$0")/bin/flask_gui_setup.sh"
source "$(dirname "$0")/bin/installers.sh"


JAVA_VERSION="17.0.10-tem"
GOVERSION="1.23.4"
GO_ARCH="amd64"
GO_OS="linux"
APPTAINER_REPO="https://github.com/apptainer/apptainer.git"
INSTALL_DIR="$HOME/.local/bin"
WORK_DIR="$PWD/resources"
CONDA_DIR="$HOME/miniconda3"
MAMBA_ENV="flask_gui"
VEP_CACHE_DIR="$PWD/resources/.vep"
REF_DIR="$PWD/resources/reference"

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
# Меню
# =======================

print_menu() {
  check_java_installed; JAVA_STATUS=$?
  check_conda_installed; CONDA_STATUS=$?
  check_mamba_installed; MAMBA_STATUS=$?
  check_nextflow_installed; NF_STATUS=$?
  check_apptainer_installed; APP_STATUS=$?
  check_vep_cache_installed; VEP_CACHE_STATUS=$?
  check_reference_installed; REF_STATUS=$?
  check_flask_installed; FLASK_STATUS=$?
  check_flask_config_exists; CONFIG_STATUS=$?

  echo
  echo "=========== МЕНЮ УСТАНОВКИ ==========="
  printf "1)  Установить Java                        [%b]\n" "$( [ $JAVA_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "2)  Установить Conda                       [%b]\n" "$( [ $CONDA_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "3)  Установить Mamba                       [%b]\n" "$( [ $MAMBA_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "4)  Установить Nextflow                    [%b]\n" "$( [ $NF_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "5)  Установить Apptainer                   [%b]\n" "$( [ $APP_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "6)  Установить VEP cache                   [%b]\n" "$( [ $VEP_CACHE_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "7)  Скачать референс hg38 и индексы BWA    [%b]\n" "$( [ $REF_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "8)  Создать conda окружение Flask GUI      [%b]\n" "$( [ $FLASK_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  printf "9)  Создать папки и конфиг для Flask GUI   [%b]\n" "$( [ $CONFIG_STATUS -eq 0 ] && echo "${green}✔${reset}" || echo "${red}✘${reset}" )"
  echo  "10)  Тестовый запуск nextflow с профилями test,apptainer"
  echo "11)  Запустить Flask GUI"
  echo "12)  Установить всё (1-9)"
  echo "0)   Выход"
  echo "======================================="
}

while true; do
  print_menu
  read -r choice
  case $choice in
    1) install_java ;;
    2) install_conda ;;
    3) install_mamba ;;
    4) install_nextflow ;;
    5) install_apptainer ;;
    6) install_vep_cache ;;
    7) download_reference ;;
    8) flask_create_env ;;
    9) flask_create_folders_and_config ;;
    10) test_nextflow_profile ;;
    11) run_flask_gui ;;
    12)
       install_java
       install_conda
       install_mamba
       install_nextflow
       install_apptainer
       install_vep_cache
       download_reference
       flask_create_env
       flask_create_folders_and_config
       ;;
    0) echo "Выход."; exit 0 ;;
    *) echo "Неверный ввод, попробуйте еще раз." ;;
  esac
done
