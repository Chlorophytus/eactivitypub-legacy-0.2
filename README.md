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

## Seeding examples
### Creating an instance keyspace
```ddl
CREATE KEYSPACE IF NOT EXISTS eactivitypub 
    WITH REPLICATION = { 
        'class' : 'NetworkTopologyStrategy', 
        'datacenter1' : 1 
    };
```
### Creating a timeline table
```ddl
CREATE TABLE IF NOT EXISTS timeline (
    recver_idx BIGINT,
    sender_idx BIGINT,
    post_time TIMESTAMP,
    post_idx BIGINT,
    post_root BIGINT,
    post_reps SET<BIGINT>,
    content TEXT,
    PRIMARY KEY ((recver_idx, post_root))
);
```
#### The schema
- `recver_idx`: Post to what? 0 if it's the world, a user ID if it's a DM.
- `sender_idx`: Post from what?
- `post_time`: When did the sender post?
- `post_idx`: This post's ID.
- `post_root`: 0 if this isn't a reply, but will point to a `post_idx` that is.
- `post_reps`: Post IDs that are replies to this.
- `content`: The content of this post.