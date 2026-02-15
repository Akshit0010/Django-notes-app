.PHONY: help build up down restart logs shell migrate createsuperuser collectstatic clean

help:
	@echo "Available commands:"
	@echo "  make build          - Build Docker images"
	@echo "  make up             - Start all containers"
	@echo "  make down           - Stop all containers"
	@echo "  make restart        - Restart all containers"
	@echo "  make logs           - View container logs"
	@echo "  make shell          - Access Django shell"
	@echo "  make migrate        - Run database migrations"
	@echo "  make createsuperuser - Create Django superuser"
	@echo "  make collectstatic  - Collect static files"
	@echo "  make clean          - Remove containers and volumes"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

shell:
	docker-compose exec web python manage.py shell

migrate:
	docker-compose exec web python manage.py migrate

createsuperuser:
	docker-compose exec web python manage.py createsuperuser

collectstatic:
	docker-compose exec web python manage.py collectstatic --noinput

clean:
	docker-compose down -v
	docker system prune -f
