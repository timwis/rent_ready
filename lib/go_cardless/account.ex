defmodule GoCardless.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:resource_id, :string, autogenerate: false}
  embedded_schema do
    field :iban, :string
    field :currency, :string
    field :owner_name, :string
    field :name, :string
    field :cash_account_type, :string
    field :status, :string
  end

  def new(%{"resourceId" => _} = attrs) do
    attrs
    |> Recase.Enumerable.convert_keys(&Recase.to_snake/1)
    |> new()
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :resource_id,
      :iban,
      :currency,
      :owner_name,
      :name,
      :cash_account_type,
      :status
    ])
    |> apply_action!(:validate)
  end
end
