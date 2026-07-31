# gloo-pg

A core gloo library for postgres.

Use alongside `gloo-db` — this gem provides the Postgres driver, `gloo-db` provides `query`/`table`.

## Usage

Load this library in a gloo script:

```gloo
> load lib db
> load lib pg
```

## Objects

- `postgres` — a Postgres database connection

## Full Reference

The object's children and messages are documented in-app once the library is loaded — `help> object postgres`.
