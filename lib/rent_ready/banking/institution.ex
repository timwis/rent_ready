defmodule RentReady.Banking.Institution do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "banking_institutions" do
    field :logo, :string
    field :name, :string

    has_many :banking_agreements, RentReady.Banking.Agreement,
      foreign_key: :banking_institution_id

    timestamps()
  end

  @doc false
  def changeset(institution, attrs) do
    institution
    |> cast(attrs, [:id, :name, :logo])
    |> validate_required([:id, :name])
  end
end
