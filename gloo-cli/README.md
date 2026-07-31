# gloo-cli

A core gloo library for command-line interface applications.

## Usage

Load this library in a gloo script:

```gloo
> load lib cli
```

## Objects

- `prompt` — CLI prompt for user input
- `select` — prompt for user to select from a list of options
- `confirm` — CLI confirmation prompt
- `menu` — a CLI menu, for a main loop or sub-menu of choices
- `menu_item` — a single element in a CLI menu
- `colorize` — write colored/styled output to the terminal
- `shell` — an interactive command-driven shell (REPL)
- `command` — a single command in a shell's command tree

## Full Reference

Every object's children and messages are documented in-app once the library is loaded — e.g. `help> object prompt`.
