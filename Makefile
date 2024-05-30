include .env

MIGRATION_FILE=./migrations.sql

ifeq ($(ALGORITHM_LOCK),COPY)
  ALGORITHM_LOCK_PART = , ALGORITHM=COPY
else ifeq ($(ALGORITHM_LOCK),INSTANT)
  ALGORITHM_LOCK_PART = , ALGORITHM=INSTANT
else ifeq ($(ALGORITHM_LOCK),INPLACE)
  ALGORITHM_LOCK_PART = , ALGORITHM=INPLACE, LOCK=NONE
else
  ALGORITHM_LOCK_PART =
endif

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Commands:"
	@echo "  start                            : Start the service with the version specified in the .env file"
	@echo "  stop                             : Stop all running services"
	@echo "  migrate                          : Re-run database migrations"
	@echo "  show                             : Show tables"
	@echo "  dql                              : Run a long-running select on bar"
	@echo "  dml                              : Run a long-running update"
	@echo "  ddl-index                        : Run an alter table to add index on foo"
	@echo "  ddl-fk                           : Run an alter table to add foreign key on bar"
	@echo "  ddl-column                       : Run an alter table to add new column on foo"
	@echo "  select [table]                   : Run a simple select against table (limit to 10)"
	@echo "  update [table] [column] [value]  : Update the first record"
	@echo "  locks                            : Show current MySQL locks"
	@echo "  wlocks                           : Watch current MySQL locks"
	@echo "  connect                          : Connect to CLI"
	@echo "  bash                             : Connect to Docker bash"
	@echo "  logs                             : Show Docker logs"

start:
	@echo "Starting $(DB_CONTAINER) service..."
	@docker-compose up -d $(DB_CONTAINER)
	@until docker-compose exec $(DB_CONTAINER) mysqladmin ping -h "localhost" --silent; do \
		echo "Waiting for MySQL..."; \
		sleep 2 > /dev/null; \
	done
	@echo "MySQL is up and running!"
	@echo "Running migrations and seeding tables with 1,000,000 may take couple of seconds!"
	@sleep 5 > /dev/null
	@$(MAKE) migrate
	@$(MAKE)

stop:
	docker-compose stop
	docker-compose down

migrate:
	@echo "Running migrations..."
	docker exec -i $(DB_CONTAINER) mysql < $(MIGRATION_FILE)
	@echo "Migrations have been executed!"

dql:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "SELECT * FROM bar WHERE SLEEP($(EXEC_DELAY))"

dml:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "UPDATE bar SET foo_id = 2 WHERE id = 1 OR (SELECT 1 FROM foo WHERE SLEEP($(EXEC_DELAY))) IS NOT NULL"

ddl-index:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "ALTER TABLE foo ADD INDEX foo_name_idx (name)$(ALGORITHM_LOCK_PART)"

ddl-fk:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "SET FOREIGN_KEY_CHECKS = 0;ALTER TABLE bar ADD CONSTRAINT bar_second_foo_FK FOREIGN KEY (second_foo_id) REFERENCES foo(id) ON DELETE CASCADE ON UPDATE CASCADE$(ALGORITHM_LOCK_PART);SET FOREIGN_KEY_CHECKS = 1;"

ddl-column:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "ALTER TABLE foo ADD info VARCHAR(255) NULL$(ALGORITHM_LOCK_PART)"

select:
	@$(eval TABLE := $(word 2, $(MAKECMDGOALS)))
	docker exec -it $(DB_CONTAINER) mysql -D db -e "SELECT * FROM $(TABLE) LIMIT 10"

update:
	@$(eval TABLE := $(word 2, $(MAKECMDGOALS)))
	@$(eval COLUMN := $(word 3, $(MAKECMDGOALS)))
	@$(eval VALUE := $(word 4, $(MAKECMDGOALS)))
	docker exec -it $(DB_CONTAINER) mysql -D db -e "UPDATE $(TABLE) SET $(COLUMN) = '$(VALUE)' WHERE id = 1"

show:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "SHOW TABLES"

connect:
	docker exec -it $(DB_CONTAINER) mysql -D db

bash:
	docker exec -it $(DB_CONTAINER) bash

logs:
	docker logs -f $(DB_CONTAINER)

locks:
	docker exec -it $(DB_CONTAINER) mysql -D db -e "SELECT * FROM performance_schema.metadata_locks"

wlocks:
	watch -n 1 $(MAKE) locks

