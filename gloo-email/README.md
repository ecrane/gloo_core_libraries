# gloo-email

A core gloo library for sending and fetching emails.

## Usage

Load this library in a gloo script:

```gloo
> load lib email
```

## Objects

- `email_smtp` — SMTP configuration, used to send email
- `email_imap` — an IMAP connection, used to fetch email
- `email` — an email message (recipient, sender, subject, body)

## Full Reference

Every object's children and messages are documented in-app once the library is loaded — e.g. `help> object email_smtp`.
