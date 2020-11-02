# > ActivityPub types
# Copyright 2020 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Eactivitypub.Types do
  defmodule ID do
    @moduledoc """
    A hash of a User for ETS.
    """
    @enforce_keys [:created, :nonce]
    defstruct created: nil, nonce: nil

    @type t :: %__MODULE__{
            created: DateTime.t(),
            nonce: integer()
          }

    @spec create :: t()
    def create() do
      nonce = :erlang.unique_integer()
      created = DateTime.utc_now()
      %__MODULE__{created: created, nonce: nonce}
    end

    @spec hash(t()) :: binary
    def hash(id) do
      Base.encode16(
        :crypto.hash(:sha3_256, [to_charlist(id.nonce), to_charlist(DateTime.to_unix(id.created))])
      )
    end
  end

  defmodule Mention do
    @moduledoc """
    A WebFingerable representation of a User.
    """
    @enforce_keys [:username, :hostname]
    defstruct username: nil, hostname: nil

    @type t :: %__MODULE__{username: binary, hostname: binary}

    @spec decode!(binary) :: Eactivitypub.Types.Mention.t()
    @doc """
    Unsafely decodes a federated mention into an Eactivitypub one.

    ## Examples

        iex> Eactivitypub.Types.Mention.decode!("chlorophytus@example.com")
        %Eactivitypub.Types.Mention{hostname: "example.com", username: "chlorophytus"}

    """
    def decode!(mention) do
      # Pass 1: Capture a possibly invalid username but a valid host
      # For Pass 1 we will use https://tools.ietf.org/html/rfc3986#appendix-B
      %{"user" => user!, "host" => host} =
        Regex.named_captures(~r/^((?<user>[[:graph:]]+)\@)(?<host>[^\/?#]*)$/u, mention)

      # Pass 2: Evaluate the username
      cond do
        not Regex.match?(~r/^.*(\@).*$/, user!) ->
          %__MODULE__{username: user!, hostname: host}
      end
    end

    @spec decode(binary) ::
            {:error, :invalid_host | :invalid_user} | {:ok, t()}
    @doc """
    Decodes a federated mention into an Eactivitypub one.

    ## Examples

        iex> Eactivitypub.Types.Mention.decode("chlorophytus@example.com")
        {:ok, %Eactivitypub.Types.Mention{hostname: "example.com", username: "chlorophytus"}}

    """
    def decode(mention) do
      case Regex.named_captures(~r/^((?<user>[[:graph:]]+)\@)(?<host>[^\/?#]*)$/u, mention) do
        %{"user" => user!, "host" => host} ->
          if not Regex.match?(~r/^.*(\@).*$/, user!) do
            {:ok, %__MODULE__{username: user!, hostname: host}}
          else
            {:error, :invalid_user}
          end

        _ ->
          {:error, :invalid_host}
      end
    end

    @spec encode(t()) :: binary
    @doc """
    Encodes an Eactivitypub mention into a federated one. No sanitisation is performed.

    ## Examples

        iex> Eactivitypub.Types.Mention.encode(%Eactivitypub.Types.Mention{hostname: "example.com", username: "chlorophytus"})
        "chlorophytus@example.com"

    """
    def encode(mention) do
      "#{mention.username}@#{mention.hostname}"
    end
  end

  defmodule User do
    @moduledoc """
    Stores a user. These can be distributed on-the-fly.

    NOTE: ID is not required, though advised to implement internally. This is a
    preliminary statement.
    """
    @enforce_keys [:preferred_username, :type, :manually_approves_followers, :discoverable]
    defstruct hashable_id: nil,
              preferred_username: nil,
              name: nil,
              summary: nil,
              type: :person,
              url: nil,
              icon: nil,
              image: nil,
              manually_approves_followers: false,
              discoverable: true,
              public_key: nil,
              featured: [],
              also_known_as: []

    @type t :: %__MODULE__{
            hashable_id: ID.t(),
            preferred_username: Mention.t(),
            name: binary,
            summary: binary,
            type: :person | :service | :application,
            url: binary,
            icon: binary,
            image: binary,
            manually_approves_followers: boolean,
            discoverable: boolean,
            public_key: :public_key.public_key(),
            featured: list,
            also_known_as: [Mention.t()]
          }
  end
end
