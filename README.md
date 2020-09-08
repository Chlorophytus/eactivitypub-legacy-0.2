# eactivitypub

Elixir-powered ActivityPub / Mastodon

## Configuration
This is not production-ready software. You should either wait on using this software, or help out.

## **Test** configuration
This is for testing only, please don't do this in production.
```shell
$ openssl req -x509 -newkey rsa:4096 -keyout apps/eactivitypub/priv/secrets/example_key.pem -out apps/eactivitypub/priv/secrets/example_crt.pem -nodes -subj '/CN=localhost'
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eactivitypub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eactivitypub, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/eactivitypub](https://hexdocs.pm/eactivitypub).

