#!/bin/bash
# Читает и проверяет переменные окружения контейнера.
# APP_PATH — корень смонтированного репозитория внутри контейнера (./:${APP_PATH}).
# Без APP_PATH и APP_HOST Nginx не узнает, куда класть магазин и какой домен слушать.

require() {
  [[ -n "${!1}" ]] || { log error "Не задана переменная $1 — укажите её в .env"; exit 1; }
}

require_01() {
  local name=$1
  local value=${!name}
  [[ -n "$value" ]] || { log error "Не задана переменная $name — укажите 0 или 1 в .env"; exit 1; }
  case $value in
    0|1) ;;
    *)
      log error "$name=$value недопустима. Допустимо: 0 или 1"
      exit 1
      ;;
  esac
}

require APP_PATH
require APP_HOST
require DB_CONNECTION
require DB_HOST
require DB_PORT
require DB_DATABASE
require DB_USERNAME
require DB_PASSWORD
require_01 OC_CRON_ENABLED
require OC_LANGUAGE
require OC_ADMIN_USER
require OC_ADMIN_PASSWORD
require OC_ADMIN_EMAIL

: "${OC_DB_PREFIX:=oc_}"

case $DB_CONNECTION in
  mysql|mariadb) ;;
  *)
    log error "DB_CONNECTION=$DB_CONNECTION неизвестна. Допустимо: mysql, mariadb"
    exit 1
    ;;
esac

if [[ ${#OC_ADMIN_USER} -lt 3 || ${#OC_ADMIN_USER} -gt 20 ]]; then
  log error "OC_ADMIN_USER должен быть от 3 до 20 символов"
  exit 1
fi

if [[ ${#OC_ADMIN_PASSWORD} -lt 5 || ${#OC_ADMIN_PASSWORD} -gt 20 ]]; then
  log error "OC_ADMIN_PASSWORD должен быть от 5 до 20 символов"
  exit 1
fi

if [[ ${MAILPIT_ENABLED+set} == set ]]; then
  require_01 MAILPIT_ENABLED
  [[ $MAILPIT_ENABLED != 1 ]] || require MAILPIT_HOST
fi

export OC_ROOT="$APP_PATH/public"

log info "Магазин: $APP_PATH  ·  домен: $APP_HOST  ·  СУБД: $DB_CONNECTION  ·  язык: $OC_LANGUAGE"
mkdir -p "$APP_PATH"
cd "$APP_PATH"
