.PHONY: up down restart logs ps validate clean

COMPOSE ?= docker compose

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

validate:
	./scripts/validate.sh

clean:
	$(COMPOSE) down --volumes --remove-orphans
