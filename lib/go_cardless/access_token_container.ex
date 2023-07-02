defmodule GoCardless.AccessTokenContainer do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.RelativeDateTime

  @primary_key false
  embedded_schema do
    field :access, :string, redact: true
    field :access_expires, RelativeDateTime
    field :refresh, :string, redact: true
    field :refresh_expires, RelativeDateTime
  end

  @doc false
  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:access, :access_expires, :refresh, :refresh_expires])
    |> apply_action!(:validate)
  end
end
