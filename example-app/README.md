# Быстрый старт 🚀

- ⬇️ Скачайте [example-app](.) (переименуйте каталог под ваш проект).
- 📄 Скопируйте `.env.example` в `.env` (см. [таблицу с переменными](#env-vars)). СУБД проекта — MariaDB.
- ⚡ Запустите проект выполнив команду из корня репозитория: `make up`.
- 📊 В логах контейнера `application` вам будет доступен процесс создания проекта.
- ✅ Завершением сборки можно считать появление строки `✅ КОНТЕЙНЕР ГОТОВ — ЗАПУСКАЮ NGINX И PHP-FPM`.

<a id="env-vars"></a>

| Название переменной | Описание переменной | Требуется |
| :------------------ | :------------------ | :-------- |
| <a id="APP_HOST"></a>[APP_HOST](#APP_HOST) | Хост вашего проекта (хост необходимо добавить в файл hosts вашей системы, пример: `127.0.0.1   opencart.docker.local`) | ✅ |
| <a id="APP_PATH"></a>[APP_PATH](#APP_PATH) | Путь внутри контейнера, куда монтируется корень репозитория (`./:${APP_PATH}`) | ✅ |
| <a id="DB_CONNECTION"></a>[DB_CONNECTION](#DB_CONNECTION) | Драйвер базы. Для этого примера — `mariadb`. Допустимо: `mysql`, `mariadb` | ✅ |
| <a id="DB_HOST"></a>[DB_HOST](#DB_HOST) | Хост базы данных (хостом БД является название контейнера СУБД из docker-compose.yml) | ✅ |
| <a id="DB_PORT"></a>[DB_PORT](#DB_PORT) | Порт базы данных. Для MariaDB и MySQL — `3306` | ✅ |
| <a id="DB_DATABASE"></a>[DB_DATABASE](#DB_DATABASE) | Название базы данных | ✅ |
| <a id="DB_USERNAME"></a>[DB_USERNAME](#DB_USERNAME) | Имя пользователя для базы данных | ✅ |
| <a id="DB_PASSWORD"></a>[DB_PASSWORD](#DB_PASSWORD) | Пароль пользователя для базы данных. Тот же пароль задаётся root-пользователю MariaDB | ✅ |
| <a id="OC_DB_PREFIX"></a>[OC_DB_PREFIX](#OC_DB_PREFIX) | Префикс таблиц. Если не задан — `oc_` | ❌ |
| <a id="OC_LANGUAGE"></a>[OC_LANGUAGE](#OC_LANGUAGE) | Язык установки, например `en-gb` или `fr-fr`. В архиве должен быть файл `install/opencart-<язык>.sql` | ✅ |
| <a id="OC_ADMIN_USER"></a>[OC_ADMIN_USER](#OC_ADMIN_USER) | Логин администратора при первой установке. От 3 до 20 символов | ✅ |
| <a id="OC_ADMIN_PASSWORD"></a>[OC_ADMIN_PASSWORD](#OC_ADMIN_PASSWORD) | Пароль администратора при первой установке. От 5 до 20 символов | ✅ |
| <a id="OC_ADMIN_EMAIL"></a>[OC_ADMIN_EMAIL](#OC_ADMIN_EMAIL) | Почта администратора при первой установке | ✅ |
| <a id="OC_CRON_ENABLED"></a>[OC_CRON_ENABLED](#OC_CRON_ENABLED) | Вкл/выкл системный CRON (1 — вкл.; раз в минуту): `php cron.php`. Допустимы только `0` или `1` | ✅ |
| <a id="MAILPIT_ENABLED"></a>[MAILPIT_ENABLED](#MAILPIT_ENABLED) | Вкл/выкл mailpit (1 — вкл.). Если задана — только `0` или `1`; любое другое значение — ошибка при старте контейнера | ❌ |
| <a id="MAILPIT_HOST"></a>[MAILPIT_HOST](#MAILPIT_HOST) | Хост mailpit. Обязательна, если [`MAILPIT_ENABLED`](#MAILPIT_ENABLED)=1 | ❌ |

## Установка OpenCart

После успешной сборки проекта можете перейти на страницу `http://APP_HOST` (заменить [**APP_HOST**](#APP_HOST) на хост из `.env` файла). Вы должны увидеть магазин `OpenCart`. Вход в админку: `http://APP_HOST/admin/` (логин и пароль — [`OC_ADMIN_USER`](#OC_ADMIN_USER) и [`OC_ADMIN_PASSWORD`](#OC_ADMIN_PASSWORD)).

1. Если в `public/` ещё нет `index.php` и `system/startup.php`, контейнер сам скачает последний релиз OpenCart 4.x с GitHub. Файлы репозитория (`docker-compose.yml`, `makefile`, `.env`, `README.md`) не перезаписываются.
2. При первом запуске установщик создаёт `public/config.php` и `public/admin/config.php` из доступов к СУБД.
3. Таблицы и демо-данные создаются автоматически после готовности базы (`php install/cli_install.php install`). Повторный запуск установку не повторяет: повторный вызов установщика удалил бы таблицы.
4. После успешной установки каталог `public/install/` удаляется.
5. 🔥 **OpenCart** успешно установлен!

Чтобы поставить магазин заново, остановите проект (`make down`) и удалите каталог `public/`.

# Дополнительные настройки 🛠️

Дополнительные настройки являются рекомендованными, но необязательными и не препятствуют успешной работе проекта.

## Настройка почты через Mailpit

👇 Если [`MAILPIT_ENABLED`](#MAILPIT_ENABLED)=1, контейнер направит `mail()` PHP в Mailpit. Письма смотрите на `http://localhost:8025`.

# Документация и команды 🎨

## Документация

1. [OpenCart](https://www.opencart.com/) — сайт проекта.
2. [Документация](https://docs.opencart.com/) — установка и настройка.
3. [Релизы](https://github.com/opencart/opencart/releases) — исходники, которые скачивает контейнер.

## Команды

<a id="команды"></a>

### Загрузить БД в контейнер (mariadb)

```bash
docker exec -i $(basename $(pwd))-database-1 sh -c 'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' < ./docker/mariadb/db.sql
```

### Выгрузить БД из контейнера (mariadb)

```bash
docker exec $(basename $(pwd))-database-1 sh -c 'mariadb-dump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' > ./docker/mariadb/db.sql
```
