defmodule GoCardless.AccountResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :resource_id, :string
    field :iban, :string
    field :currency, :string
    field :owner_name, :string
    field :name, :string
    field :cash_account_type, :string
    field :status, :string
  end

  def new(%{"resourceId" => _} = camel_case_attrs) do
    camel_case_attrs
    |> Recase.Enumerable.convert_keys(&Recase.to_snake/1)
    |> new()
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :id,
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
