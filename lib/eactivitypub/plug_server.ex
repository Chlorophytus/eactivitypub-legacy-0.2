require Logger

defmodule Eactivitypub.PlugServer do
  import Plug.Conn

  def init(options) do
    options
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn |> put_resp_content_type("text/plain") |> send_resp(200, "Unimplemented")
  end
end
