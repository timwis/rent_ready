defmodule RentReady.Banking.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.TransactionResponse

  schema "transactions" do
    belongs_to :bank_account, RentReady.Banking.BankAccount

    field :gc_id, :string
    field :booked_at, :date
    field :type, Ecto.Enum, values: [:payment], default: :payment
    field :amount, Money.Ecto.Composite.Type
    field :raw_data, :map

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:gc_id, :booked_at, :amount, :raw_data])
    |> validate_required([:gc_id, :booked_at, :amount, :raw_data])
    |> unique_constraint(:gc_id)
  end

  def from_go_cardless(%TransactionResponse{} = transaction_response) do
    %{
      gc_id: transaction_response.internal_transaction_id,
      booked_at: transaction_response.booking_date,
      amount: transaction_response.transaction_amount,
      raw_data: transaction_response
    }
  end
end
