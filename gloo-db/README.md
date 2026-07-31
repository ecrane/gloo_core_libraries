# gloo-db

A core gloo library for database operations.

Use this library and one of the database-specific driver libraries (`gloo-pg`, `gloo-mysql`, `gloo-sqlite`) to interact with databases.

## Usage

Load this library, plus a driver, in a gloo script:

```gloo
> load lib db
> load lib sqlite
```

## Objects

- `query` — a SQL query (SELECT, INSERT, UPDATE, or other statement)
- `table` — a data table

## Full Reference

Every object's children and messages are documented in-app once the library is loaded — e.g. `help> object query`.
