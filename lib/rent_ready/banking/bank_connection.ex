defmodule RentReady.Banking.BankConnection do
  use Ecto.Schema
  import Ecto.Changeset

  alias GoCardless.{EndUserAgreementResponse, RequisitionResponse}

  schema "bank_connections" do
    belongs_to :user, RentReady.Accounts.User
    belongs_to :institution, RentReady.Banking.Institution, type: :string

    field :gc_agreement_id, Ecto.UUID
    field :gc_requisition_id, Ecto.UUID
    field :reference, Ecto.UUID
    field :link, :string
    field :status, Ecto.Enum, values: [:CR, :GC, :UA, :RJ, :SA, :GA, :LN, :SU, :EX]
    field :expires_at, :utc_datetime

    has_many :bank_accounts, RentReady.Banking.BankAccount

    timestamps()
  end

  @doc false
  def create_changeset(connection, attrs) do
    connection
    |> cast(attrs, [
      :institution_id,
      :gc_agreement_id,
      :gc_requisition_id,
      :reference,
      :link,
      :status,
      :expires_at
    ])
    |> validate_required([
      :institution_id,
      :gc_agreement_id,
      :gc_requisition_id,
      :reference,
      :link,
      :status,
      :expires_at
    ])
  end

  def update_changeset(connection, attrs) do
    connection
    |> cast(attrs, [:status])
    |> cast_assoc(:bank_accounts, with: &RentReady.Banking.BankAccount.changeset/2)
    |> validate_required([:status])
  end

  def from_go_cardless(
        %EndUserAgreementResponse{} = agreement,
        %RequisitionResponse{} = requisition
      ) do
    %{
      institution_id: agreement.institution_id,
      gc_agreement_id: agreement.id,
      gc_requisition_id: requisition.id,
      reference: requisition.reference,
      link: requisition.link,
      status: requisition.status,
      expires_at: expires_at(agreement.access_valid_for_days)
    }
  end

  def from_go_cardless(%RequisitionResponse{} = requisition, accounts) do
    %{
      status: requisition.status,
      bank_accounts: Enum.map(accounts, &RentReady.Banking.BankAccount.from_go_cardless/1)
    }
  end

  defp expires_at(days_from_now) do
    DateTime.add(DateTime.utc_now(), days_from_now, :day)
  end
end
