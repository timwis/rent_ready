defmodule RentReady.Banking.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.AccountResponse

  schema "bank_accounts" do
    belongs_to :bank_connection, RentReady.Banking.BankConnection

    field :gc_id, :string
    field :iban, RentReady.Encrypted.Binary, redact: true
    field :name, :string

    # https://open-banking.pass-consulting.com/json_ExternalCashAccountType1Code.html
    field :type, Ecto.Enum,
      values: [
        :CACC,
        :CASH,
        :CHAR,
        :CISH,
        :COMM,
        :CPAC,
        :LLSV,
        :LOAN,
        :MGLD,
        :MOMA,
        :NREX,
        :ODFT,
        :ONDP,
        :OTHR,
        :SACC,
        :SLRY,
        :SVGS,
        :TAXE,
        :TRAN,
        :TRAS
      ]

    timestamps()
  end

  @doc false
  def changeset(bank_account, attrs) do
    bank_account
    |> cast(attrs, [:gc_id, :iban, :name, :type])
    |> validate_required([:gc_id])
  end

  def from_go_cardless(%AccountResponse{} = account_response) do
    %{
      gc_id: account_response.resource_id,
      iban: account_response.iban,
      name: account_response.name,
      type: account_response.cash_account_type
    }
  end
end
