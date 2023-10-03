defmodule GoCardless.BalanceResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :balance_amount, Money.Currency.Ecto.Type
    field :balance_type, :string
    field :reference_date, :date
  end

  def new(%{"balanceAmount" => _} = attrs) do
    attrs
    |> Recase.Enumerable.convert_keys(&Recase.to_snake/1)
    |> new()
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:balance_amount, :balance_type, :reference_date])
    |> apply_action!(:validate)
  end
end
