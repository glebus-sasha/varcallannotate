#!/bin/bash

echo "🚨 Начинаем удаление Java, Nextflow, SDKMAN, Conda и Mamba..."

# === Удаление nextflow ===
echo "🧹 Удаляем Nextflow..."

NEXTFLOW_PATH=$(command -v nextflow || which nextflow)

if [ -n "$NEXTFLOW_PATH" ]; then
    echo "🔍 Найден nextflow: $NEXTFLOW_PATH"
    rm -f "$NEXTFLOW_PATH" && echo "🗑️ Удалён: $NEXTFLOW_PATH"
else
    echo "✅ Nextflow не найден"
fi

# Удалим возможные копии nextflow
for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -f "$dir/nextflow" ]; then
        echo "🗑️ Удаляем $dir/nextflow"
        rm -f "$dir/nextflow"
    fi
done

# === Удаление SDKMAN и Java Temurin ===
if [ -d "$HOME/.sdkman" ]; then
    echo "🧹 Удаляем SDKMAN и Java..."
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    JAVA_VERSION=$(sdk current java | grep -o 'temurin[^ ]*')
    if [ -n "$JAVA_VERSION" ]; then
        sdk uninstall java "$JAVA_VERSION"
    fi

    sdk uninstall nextflow || true
    rm -rf "$HOME/.sdkman"
    sed -i '/sdkman/d' "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null
    echo "✅ SDKMAN и Java удалены"
else
    echo "ℹ️ SDKMAN не найден"
fi

# === Удаление Conda ===
if command -v conda &> /dev/null; then
    echo "🧹 Удаляем Conda..."
    CONDA_PATH=$(dirname "$(dirname "$(which conda)")")
    echo "🔍 Найдена по пути: $CONDA_PATH"
    rm -rf "$CONDA_PATH"
    sed -i '/conda/d' "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null
    echo "✅ Conda удалена"
else
    echo "ℹ️ Conda не найдена"
fi

# === Удаление Mamba ===
if command -v mamba &> /dev/null; then
    echo "🧹 Удаляем Mamba..."
    MAMBA_PATH=$(command -v mamba)
    echo "🔍 Найден mamba: $MAMBA_PATH"
    rm -f "$MAMBA_PATH"
    echo "✅ Mamba удалена"
else
    echo "ℹ️ Mamba не найдена"
fi

echo -e "\n✅ Удаление завершено!"
echo "🔁 Перезапусти терминал или выполни: source ~/.bashrc"
