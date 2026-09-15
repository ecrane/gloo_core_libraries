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
│   ├── test_helper.rb    Loads dev/gloo's test scaffolding, then `require`s this gem
│   ├── objs/             Ruby unit tests for object types
│   └── *.test.gloo       Gloo integration tests (where applicable)
├── Rakefile              `rake test` — runs test/**/*_test.rb via Minitest
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
3. Add Ruby unit tests in `test/objs/` — `test_helper.rb`/`Rakefile` are identical across every gem, so copy them from any existing gem rather than writing from scratch
4. Add (or extend) the `.gloo` integration test in `test/*.test.gloo` — typename, short_typename, messages, and default-children at minimum, matching the depth of an existing per-object file in another gem
5. Run tests: `rake test` from within the gem directory (Ruby) and `gloo --test ./test` (`.gloo`) — see full template and gotchas in `gloo_meta/docs/core_library_guide.md`

## Running Tests

```bash
cd gloo-<name>
rake test              # Ruby unit tests for this gem only
gloo --test ./test     # .gloo integration tests for this gem only
```

Run every gem's Ruby unit tests in one pass from the `gloo_core_libraries` root:

```bash
rake test
```

**If you've edited a gem's `lib/` code and are about to run its `.gloo` suite**, use `RUBYLIB="$(pwd)/lib" gloo --test ./test`, not bare `gloo --test` — `.gloo` tests load a core lib via `load lib <name>`, which resolves purely through RubyGems (whatever's `gem install`'d) and has no awareness of your local checkout. Bare `gloo --test` will silently test the stale installed gem instead of your edit. `rake test` doesn't have this problem — it doesn't need `RUBYLIB`.
