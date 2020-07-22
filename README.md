# eactivitypub
Erlang-powered ActivityPub / Mastodon
## Configuration
This is not production-ready software. You should either wait on using this software, or help out.
## **Test** configuration
This is for testing only, please don't do this in production.
```shell
$ openssl req -x509 -newkey rsa:4096 -keyout apps/eactivitypub/priv/secrets/example_key.pem -out apps/eactivitypub/priv/secrets/example_crt.pem -nodes -subj '/CN=localhost'
```