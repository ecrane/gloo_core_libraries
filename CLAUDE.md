@/Users/ecrane/dev/gloo_meta/CLAUDE.md

# Gloo Core Libraries

Standard library gems that extend the core gloo interpreter. Each is an independent Ruby gem with its own `lib/`, `test/`, and gemspec.

## Libraries

| Directory | Gem | Adds |
|-----------|-----|------|
| `gloo-web/` | `gloo-web` | Web server, pages, layouts, forms, routing, sessions, AJAX, partial, response/request |
| `gloo-db/` | `gloo-db` | Database abstraction — query, query_result, table |
| `gloo-mysql/` | `gloo-mysql` | MySQL driver |
| `gloo-pg/` | `gloo-pg` | PostgreSQL driver |
| `gloo-sqlite/` | `gloo-sqlite` | SQLite driver |
| `gloo-cli/` | `gloo-cli` | CLI objects — menu, menu_item, prompt, confirm, select, colorize, shell |
| `gloo-test/` | `gloo-test` | Test runner — assert/refute verbs, test object type |
| `gloo-email/` | `gloo-email` | Email sending |
| `gloo-md/` | `gloo-md` | Markdown rendering |
| `gloo-beep/` | `gloo-beep` | Audio notifications |

## Library Structure

Each gem follows the same layout:

```
gloo-<name>/
├── lib/
│   ├── gloo-<name>.rb    Entry point — registers objects/verbs with gloo
│   ├── objs/             Object type implementations (.rb files)
│   ├── verbs/            Verb implementations (if any)
│   └── VERSION           Version string
├── test/
│   ├── objs/             Ruby unit tests for object types
│   └── *.test.gloo       Gloo integration tests (where applicable)
└── gloo-<name>.gemspec
```

## Key Library Details

### gloo-web
```
lib/
├── objs/     element, field, form, page, partial, svr (server)
└── routing/  router, resource_router, show_routes
```
Object types: `page`, `page_file`, `server`, `form`, `element`, `field`, `partial`, `request`, `response`

### gloo-db
```
lib/   query.rb, query_result.rb, table.rb
```
Object types: `query` (with mysql/pg/sqlite drivers in their respective gems)

### gloo-cli
```
lib/   menu.rb, menu_item.rb, prompt.rb, confirm.rb, select.rb,
       cli_colorize.rb, shell.rb, shell_runner.rb, shell_context.rb,
       command.rb, command_node.rb
```
Object types: `menu`, `menu_item`, `prompt`, `confirm`, `select`, `colorize`, `shell`

## Adding a New Object Type

1. Add a `.rb` file in `lib/objs/` inheriting from gloo's base `Obj` class
2. Register the type in the gem's main `lib/gloo-<name>.rb` entry point
3. Add tests in `test/objs/`
4. Run tests: `rake test` from within the gem directory

## Running Tests

```bash
cd gloo-<name>
rake test
```
