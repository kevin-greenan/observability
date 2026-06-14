.PHONY: up down restart logs ps validate siem-smoke-test detection-test alert-routing-test security-boundary-test identity-secrets-test restore-test production-deployment-test clean

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

identity-secrets-test:
	./scripts/identity-secrets-test.sh

restore-test:
	./scripts/restore-test.sh

production-deployment-test:
	./scripts/production-deployment-test.sh

clean:
	$(COMPOSE) down --volumes --remove-orphans
