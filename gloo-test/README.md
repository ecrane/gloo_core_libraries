# gloo-test

A core gloo library for unit testing gloo code.

## Usage

Loaded automatically when running gloo in test mode:

```gloo
> gloo --test ./path/to/tests/
```

It can also be loaded explicitly in a script, like any other core library:

```gloo
> load lib test
```

## Objects

- `test` — a single gloo test

## Verbs

- `assert` — assert an expectation about the state or result of a prior command
- `refute` — refute an expectation about the state or result of a prior command

## Full Reference

Every object/verb's full syntax is documented in-app once the library is loaded — e.g. `help> verb assert`.
