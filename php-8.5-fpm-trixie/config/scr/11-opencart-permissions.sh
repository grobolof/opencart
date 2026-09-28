#!/bin/bash
# Выставляет ACL на каталог магазина, чтобы PHP-FPM мог писать кэш, сессии и картинки.
# На bind-mount (macOS Docker Desktop) POSIX ACL часто недоступен — тогда chmod.

if [[ ! -d "$OC_ROOT" ]]; then
  log warning "Каталог магазина не найден — права пропускаю"
else
  log info "Выставляю права на каталог магазина…"
  HTTPDUSER=$(ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d' ' -f1)
  [[ -n "$HTTPDUSER" ]] || HTTPDUSER=www-data

  mkdir -p \
    "$OC_ROOT/image" \
    "$OC_ROOT/system/storage/cache" \
    "$OC_ROOT/system/storage/download" \
    "$OC_ROOT/system/storage/logs" \
    "$OC_ROOT/system/storage/session" \
    "$OC_ROOT/system/storage/upload"

  if setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "$OC_ROOT" 2>/dev/null \
     && setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "$OC_ROOT" 2>/dev/null; then
    log success "Права на каталог магазина выставлены"
  else
    chmod -R a+rwX "$OC_ROOT"
    log success "Права на каталог магазина выставлены (chmod: ACL недоступен на этом томе)"
  fi
fi
