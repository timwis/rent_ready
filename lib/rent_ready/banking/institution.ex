defmodule RentReady.Banking.Institution do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.InstitutionResponse

  @primary_key {:id, :string, autogenerate: false}
  schema "institutions" do
    field :logo, :string
    field :name, :string
    field :transaction_days, :integer, default: 90

    has_many :bank_connections, RentReady.Banking.BankConnection

    timestamps()
  end

  @doc false
  def changeset(institution, attrs) do
    institution
    |> cast(attrs, [:id, :name, :logo, :transaction_days])
    |> validate_required([:id, :name])
  end

  def from_go_cardless(%InstitutionResponse{} = institution_response) do
    %{
      id: institution_response.id,
      name: institution_response.name,
      logo: institution_response.logo,
      transaction_days: institution_response.transaction_total_days
    }
  end
end
