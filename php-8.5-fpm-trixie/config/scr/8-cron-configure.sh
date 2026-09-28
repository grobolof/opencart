#!/bin/bash
# При OC_CRON_ENABLED=1 вешает поминутный php cron.php.
# При 0 системный крон не ставится.
# На первом запуске магазин ещё не установлен — тогда шаг повторит скрипт установки.

opencart_installed() {
  [[ -f "$OC_ROOT/config.php" ]] && grep -q "define('DIR_APPLICATION'" "$OC_ROOT/config.php"
}

configure_cron() {
  if [[ ! -f "$OC_ROOT/cron.php" ]]; then
    log warning "cron.php не найден — крон пропускаю"
  elif ! opencart_installed; then
    log warning "OpenCart ещё не установлен — крон настрою после установки"
  elif [[ $OC_CRON_ENABLED != 1 ]]; then
    crontab -r 2>/dev/null || true
    log warning "Крон выключен — задачи OpenCart не запускаются по расписанию"
  else
    log info "Включаю планировщик OpenCart: php cron.php каждую минуту…"
    { env; echo "*/1 * * * * cd ${OC_ROOT} && /usr/local/bin/php cron.php >> /dev/null 2>&1"; } | crontab -
    log success "Крон настроен"
  fi
}

configure_cron
