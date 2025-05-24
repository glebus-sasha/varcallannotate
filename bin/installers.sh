#!/bin/bash
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
  source ~/.bashrc
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

install_conda() {
  if check_conda_installed; then
    echo_status 0 "Conda уже установлена"
    return 0
  fi
  echo "Устанавливаем Miniconda..."
  wget -O ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash ~/miniconda.sh -b -p "$CONDA_DIR"
  rm ~/miniconda.sh
  export PATH="$CONDA_DIR/bin:$PATH"
  eval "$($CONDA_DIR/bin/conda shell.bash hook)"
  conda init
  echo_status $? "Установка Miniconda завершена"
}

install_mamba() {
  if check_mamba_installed; then
    echo_status 0 "Mamba уже установлена"
    return 0
  fi
  echo "Устанавливаем Mamba через Conda..."
  export PATH="$CONDA_DIR/bin:$PATH"
  eval "$($CONDA_DIR/bin/conda shell.bash hook)"
  conda install -y -n base -c conda-forge mamba
  echo_status $? "Установка Mamba завершена"
}

install_vep_cache() {
  if check_vep_cache_installed; then
    echo_status 0 "Кэш VEP уже установлен"
    return 0
  fi

  echo "Кэш VEP не найден в $VEP_CACHE_DIR, загружаю..."
  mkdir -p "$VEP_CACHE_DIR"
  curl -L -o "$VEP_CACHE_DIR/vep_cache.tar.gz" "https://ftp.ensembl.org/pub/release-114/variation/indexed_vep_cache/homo_sapiens_vep_114_GRCh38.tar.gz"
  tar -xzvf "$VEP_CACHE_DIR/vep_cache.tar.gz" -C "$VEP_CACHE_DIR"
  rm "$VEP_CACHE_DIR/vep_cache.tar.gz"
  echo_status $? "Кэш VEP установлен"
}

download_reference() {
  if check_reference_installed; then
    echo_status 0 "Референс уже установлен"
    return 0
  fi

  local BASE_URL="https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0"
  mkdir -p "$REF_DIR"
  mkdir -p "$REF_DIR/faidx"
  mkdir -p "$REF_DIR/bwaidx"

  cd "$REF_DIR" || exit

  echo "📥 Скачиваем референсный геном hg38..."

  (curl -s -O "$BASE_URL/Homo_sapiens_assembly38.fasta" && echo "✅ Homo_sapiens_assembly38.fasta скачан") &
  (curl -s -O "$BASE_URL/Homo_sapiens_assembly38.fasta.fai" && echo "✅ Homo_sapiens_assembly38.fasta.fai скачан") &

  echo "📥 Скачиваем индексы BWA..."
  for ext in amb ann bwt pac sa; do
    (
      curl -s -O "$BASE_URL/Homo_sapiens_assembly38.fasta.64.$ext" && echo "✅ Homo_sapiens_assembly38.fasta.64.$ext скачан"
    ) &
  done

  wait

  echo "📦 Переименовываем и раскладываем файлы..."

  mv Homo_sapiens_assembly38.fasta "$REF_DIR/hg38.fa"
  mv Homo_sapiens_assembly38.fasta.fai "$REF_DIR/faidx/hg38.fa.fai"

  for ext in amb ann bwt pac sa; do
    mv "Homo_sapiens_assembly38.fasta.64.$ext" "$REF_DIR/bwaidx/hg38.fa.$ext"
  done

  echo_status $? "Референс и индексы успешно установлены"
}

