defmodule RentReady.Banking.Agreement do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.EndUserAgreementResponse

  schema "banking_agreements" do
    field :expires_at, :utc_datetime
    field :external_id, Ecto.UUID

    belongs_to :user, RentReady.Accounts.User
    belongs_to :banking_institution, RentReady.Banking.Institution, type: :string

    has_many :banking_requisitions, RentReady.Banking.Requisition,
      foreign_key: :banking_agreement_id

    timestamps()
  end

  @doc false
  def changeset(agreement, attrs) do
    agreement
    |> cast(attrs, [:external_id, :expires_at, :banking_institution_id])
    |> validate_required([:external_id, :expires_at, :banking_institution_id])
  end

  def from_go_cardless(%EndUserAgreementResponse{} = remote_agreement) do
    %{
      external_id: remote_agreement.id,
      expires_at: expires_at(remote_agreement.access_valid_for_days),
      banking_institution_id: remote_agreement.institution_id
    }
  end

  defp expires_at(days_from_now) do
    DateTime.add(DateTime.utc_now(), days_from_now, :day)
  end
end
