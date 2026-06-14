.PHONY: up down restart logs ps validate siem-smoke-test detection-test alert-routing-test security-boundary-test clean

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

siem-smoke-test:
	./scripts/siem-smoke-test.sh

detection-test:
	./scripts/detection-test.sh

alert-routing-test:
	./scripts/alert-routing-test.sh

security-boundary-test:
	./scripts/security-boundary-test.sh

clean:
	$(COMPOSE) down --volumes --remove-orphans
