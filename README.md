# Dummy MySQL Locks Simulation
This project is created to simulate MySQL locks using a Docker environment to help understand the behavior of online DDL operations and their impact on database locks, as discussed in [this article](https://medium.com/@hamidrezaniazi/behind-the-scenes-of-mysql-online-ddl-locks-638804b777b3).

## Requirements
- Docker
- Docker Compose

## Setup
Clone the repository:

```sh
git clone <repository-url>
cd dummy-mlocks-master
```

Copy the example environment file:

```sh
cp .env.example .env
```

Update the `.env` file with your configurations if needed.
- `DB_CONTAINER` : The name of the Docker container running the MySQL database. Possible values are `mlocks-v8` for MySQL 8.3 or `mlocks-v5` for MySQL 5.7.
- `EXEC_DELAY` : The delay in seconds used for simulating long-running operations.
- `ALGORITHM_LOCK` : The algorithm and lock type used for online DDL operations. Possible values are `INSTANT`, `INPLACE`, or `COPY`.


Build and start the Docker containers:

```sh
make start
```

## Makefile Functions
The Makefile includes several convenient functions for managing the Docker environment:

- `make migrate` : Re-runs database migrations using the migrations.sql file.
- `make show` : Displays the tables in the database.
- `make dql` : Runs a long-running SELECT query on the bar table.
- `make dml` : Runs a long-running UPDATE query.
- `make ddl-index` : Adds an index to the foo table.
- `make ddl-fk` : Adds a foreign key to the bar table.
- `make ddl-column` : Adds a new column to the foo table.
- `make select [table]` : Runs a simple SELECT query against the specified table (limits to 10 rows).
- `make update [table] [column] [value]` : Updates the first record in the specified table.
- `make locks` : Displays the current MySQL locks.
- `make wlocks` : Watches the current MySQL locks in real-time.
- `make connect` : Connects to the MySQL CLI.
- `make bash` : Connects to the Docker container's bash shell.
- `make logs` : Displays Docker logs.

Clean Up
To stop and remove all running containers and networks created by Docker Compose, run:

```sh
make stop
```
