# gloo-web

A core gloo library with a web server and web application framework.

Provides pages, forms, and HTML elements, hosted by an in-process web server, with routing, sessions, and AJAX support built in.

## Usage

Load this library in a gloo script:

```gloo
> load lib web
```

## Objects

- `server` — a web server running inside gloo
- `page` — a web page hosted in a gloo web server
- `partial` — a partial web page (a reusable fragment, rendered into other pages)
- `form` — an HTML form, containing a collection of form fields
- `field` — an HTML form field (text field, checkbox, etc.)
- `element` — an HTML element

## Full Reference

Every object's children and messages are documented in-app once the library is loaded — e.g. `help> object page`.
