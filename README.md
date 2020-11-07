# eactivitypub
Elixir-powered ActivityPub / Mastodon

## Testbench examples
Doing this...
```elixir
iex> Enum.map(1..20, fn post -> Eactivitypub.Timeline.post(Eactivitypub.Timeline, post) end)
[:ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok,
 :ok, :ok, :ok, :ok]
```
...then using the JSON API would result in...
```json
{"object":[20,19,18,17,16],"status":0}
```