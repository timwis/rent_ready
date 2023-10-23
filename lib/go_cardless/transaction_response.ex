defmodule GoCardless.TransactionResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :status, :string
    field :booking_date, :date
    field :value_date, :date
    field :booking_date_time, :utc_datetime
    field :value_date_time, :utc_datetime
    field :transaction_amount, Money.Ecto.Composite.Type
    field :debtor_name, :string
    field :creditor_name, :string
    field :remittance_information_unstructured, :string
    field :proprietary_bank_transaction_code, :string
    field :internal_transaction_id, :string
  end

  def new(%{"transactionId" => transaction_id} = attrs) do
    attrs
    |> Map.put("id", transaction_id)
    |> Recase.Enumerable.convert_keys(&Recase.to_snake/1)
    |> Map.update!("transaction_amount", fn val ->
      Money.parse!(val["amount"], val["currency"])
    end)
    |> new()
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :id,
      :status,
      :booking_date,
      :value_date,
      :booking_date_time,
      :value_date_time,
      :transaction_amount,
      :debtor_name,
      :creditor_name,
      :remittance_information_unstructured,
      :proprietary_bank_transaction_code,
      :internal_transaction_id
    ])
    |> apply_action!(:validate)
  end
end
