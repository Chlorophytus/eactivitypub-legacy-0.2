# > Interface with Scylla with Rust NIFs
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
defmodule Eactivitypub.Casa do
  use Rustler, otp_app: :eactivitypub, crate: :casa

  defmodule User do
    @enforce_keys [:name, :unix_created]
    defstruct name: "ERROR", unix_created: 0
    @type t :: %__MODULE__{name: binary, unix_created: non_neg_integer}

  end

  @spec user_put(User.t()) :: :ok
  def user_put(_arg1), do: :erlang.nif_error(:nif_not_loaded)
end
