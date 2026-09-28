include .env

# Запустить контейнеры:
up:
	docker compose up -d --build --remove-orphans

# Остановить контейнеры:
stop:
	docker compose stop

# Остановить и удалить контейнеры:
down:
	docker compose down -v

# КОМАНДЫ ДОСТУПНЫ ПРИ УСЛОВИИ ЧТО ПРОЕКТ OPENCART УЖЕ СОЗДАН:

## Произвольная команда PHP из корня магазина:
php: ## Пример: make php CMD="cron.php"
	docker compose exec -it application php $(APP_PATH)/public/$(CMD)
