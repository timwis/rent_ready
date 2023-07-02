defmodule GoCardless.Institution do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :name, :string
    field :bic, :string
    field :transaction_total_days, :string
    field :countries, {:array, :string}
    field :logo, :string
  end

  @doc false
  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:id, :name, :bic, :transaction_total_days, :countries, :logo])
    |> apply_action!(:validate)
  end
end
