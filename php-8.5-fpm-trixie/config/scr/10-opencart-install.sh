#!/bin/bash
# Ставит магазин через install/cli_install.php, когда база уже принимает соединения.
# Повторный запуск ничего не переустанавливает: смотрим DIR_APPLICATION в config.php.
# Установщик OpenCart при повторе удаляет таблицы, поэтому второй проход запрещён.
# Если СУБД ещё не готова — шаг не роняет контейнер, только предупреждает.

opencart_installed() {
  [[ -f "$OC_ROOT/config.php" ]] && grep -q "define('DIR_APPLICATION'" "$OC_ROOT/config.php"
}

ensure_config() {
  local dest=$1
  local dist=$2
  if [[ -f "$dest" ]] && grep -q "define('DIR_APPLICATION'" "$dest"; then
    return 0
  fi
  if [[ -f "$dist" ]]; then
    cp "$dist" "$dest"
  else
    : > "$dest"
  fi
  chmod 666 "$dest" || true
}

run_install() {
  php "$OC_ROOT/install/cli_install.php" install \
    --username "$OC_ADMIN_USER" \
    --email "$OC_ADMIN_EMAIL" \
    --password "$OC_ADMIN_PASSWORD" \
    --http_server "http://${APP_HOST}/" \
    --language "$OC_LANGUAGE" \
    --db_driver mysqli \
    --db_hostname "$DB_HOST" \
    --db_username "$DB_USERNAME" \
    --db_password "$DB_PASSWORD" \
    --db_database "$DB_DATABASE" \
    --db_port "$DB_PORT" \
    --db_prefix "$OC_DB_PREFIX"
}

if [[ ! -f "$OC_ROOT/index.php" ]]; then
  log warning "OpenCart не найден — установку пропускаю"
elif opencart_installed; then
  log success "OpenCart уже установлен"
elif [[ ! -f "$OC_ROOT/install/cli_install.php" ]]; then
  log warning "Установщик не найден — удалите public/ и запустите контейнер снова, чтобы скачать OpenCart заново"
else
  sql="$OC_ROOT/install/opencart-${OC_LANGUAGE}.sql"
  if [[ ! -f "$sql" ]]; then
    available="$(find "$OC_ROOT/install" -name 'opencart-*.sql' -printf '%f\n' | sed -e 's/^opencart-//' -e 's/\.sql$//' | paste -sd ', ' -)"
    log error "OC_LANGUAGE=$OC_LANGUAGE нет в поставке. Доступно: ${available:-нет}"
    exit 1
  fi

  log info "Готовлю config.php для установщика…"
  ensure_config "$OC_ROOT/config.php" "$OC_ROOT/config-dist.php"
  ensure_config "$OC_ROOT/admin/config.php" "$OC_ROOT/admin/config-dist.php"

  log info "Жду СУБД $DB_HOST:$DB_PORT и устанавливаю OpenCart…"
  if ! wait-for-it "${DB_HOST}:${DB_PORT}" -t 60; then
    log warning "СУБД не отвечает — установку пропускаю"
  else
    installed=0
    output=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      if output="$(run_install 2>&1)" && [[ "$output" == *"SUCCESS!"* ]]; then
        installed=1
        break
      fi
      sleep 3
    done
    if [[ $installed == 1 ]]; then
      rm -rf "$OC_ROOT/install"
      log success "OpenCart установлен: http://$APP_HOST  ·  админка: http://$APP_HOST/admin/"
      configure_cron
    else
      log warning "OpenCart не установлен — проверьте подключение к БД"
      printf '%s\n' "$output"
    fi
  fi
fi
