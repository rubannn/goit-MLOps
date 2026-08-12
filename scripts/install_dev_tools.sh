#!/usr/bin/env bash
#
# Перевіряє наявність Docker, Docker Compose V2, Python >= 3.13, pip
# та Python-бібліотек torch, torchvision, pillow.
# Якщо чогось не вистачає - намагається встановити або виводить інструкцію.
# Результати записуються у install.log. Скрипт можна запускати повторно.

LOG_FILE="install.log"
MIN_PYTHON_VERSION="3.13"

# Визначаємо команду python один раз (на деяких системах є лише "python")
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    PYTHON_BIN=""
fi

# Очищуємо лог перед новим запуском
echo "Перевірку середовища розпочато: $(date)" > "$LOG_FILE"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# --- Перевірка Docker ---
log "== Docker =="
if command -v docker >/dev/null 2>&1; then
    docker --version | tee -a "$LOG_FILE"
    log "OK: Docker встановлено."
else
    log "ПОМИЛКА: Docker не знайдено."
    log "Встановіть Docker: https://docs.docker.com/get-docker/"
fi

# --- Перевірка Docker Compose V2 ---
log "== Docker Compose V2 =="
if docker compose version >/dev/null 2>&1; then
    docker compose version | tee -a "$LOG_FILE"
    log "OK: Docker Compose V2 встановлено."
else
    log "ПОМИЛКА: команда 'docker compose version' не працює."
    log "Оновіть Docker Desktop/Engine до версії з Compose V2."
fi

# --- Перевірка Python ---
log "== Python =="
if [ -n "$PYTHON_BIN" ]; then
    PYTHON_VERSION=$("$PYTHON_BIN" -c "import platform; print(platform.python_version())")
    log "Знайдено Python версії: $PYTHON_VERSION"

    # Порівнюємо версії через sort -V
    LOWEST=$(printf '%s\n%s\n' "$PYTHON_VERSION" "$MIN_PYTHON_VERSION" | sort -V | head -n 1)
    if [ "$LOWEST" = "$MIN_PYTHON_VERSION" ]; then
        log "OK: версія Python >= $MIN_PYTHON_VERSION."
    else
        log "ПОМИЛКА: потрібен Python >= $MIN_PYTHON_VERSION, встановлено $PYTHON_VERSION."
        log "Встановіть Python $MIN_PYTHON_VERSION: https://www.python.org/downloads/"
    fi
else
    log "ПОМИЛКА: python3 не знайдено."
    log "Встановіть Python $MIN_PYTHON_VERSION: https://www.python.org/downloads/"
fi

# --- Перевірка pip ---
log "== pip =="
if [ -n "$PYTHON_BIN" ] && "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
    "$PYTHON_BIN" -m pip --version | tee -a "$LOG_FILE"
    log "OK: pip встановлено."
else
    log "ПОМИЛКА: pip не знайдено."
    log "Встановіть pip командою: $PYTHON_BIN -m ensurepip --upgrade"
fi

# --- Перевірка Python-бібліотек ---
check_python_package() {
    PACKAGE_NAME="$1"
    IMPORT_NAME="$2"

    log "== $PACKAGE_NAME =="
    if [ -z "$PYTHON_BIN" ]; then
        log "ПРОПУЩЕНО: немає доступного Python для перевірки $PACKAGE_NAME."
        return
    fi

    if "$PYTHON_BIN" -c "import $IMPORT_NAME" >/dev/null 2>&1; then
        VERSION=$("$PYTHON_BIN" -c "import $IMPORT_NAME; print($IMPORT_NAME.__version__)" 2>/dev/null)
        log "OK: $PACKAGE_NAME вже встановлено (версія $VERSION)."
    else
        log "Бібліотеку $PACKAGE_NAME не знайдено, намагаємось встановити..."
        "$PYTHON_BIN" -m pip install "$PACKAGE_NAME" >> "$LOG_FILE" 2>&1
        if "$PYTHON_BIN" -c "import $IMPORT_NAME" >/dev/null 2>&1; then
            log "OK: $PACKAGE_NAME успішно встановлено."
        else
            log "ПОМИЛКА: не вдалося встановити $PACKAGE_NAME. Встановіть вручну: pip install $PACKAGE_NAME"
        fi
    fi
}

check_python_package "torch" "torch"
check_python_package "torchvision" "torchvision"
check_python_package "pillow" "PIL"

log ""
log "Перевірку середовища завершено: $(date)"
log "Детальніше дивіться у файлі $LOG_FILE"
