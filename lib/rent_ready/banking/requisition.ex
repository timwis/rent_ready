defmodule RentReady.Banking.Requisition do
  use Ecto.Schema
  import Ecto.Changeset
  require IEx

  alias GoCardless.RequisitionResponse

  schema "banking_requisitions" do
    field :external_id, Ecto.UUID
    field :status, Ecto.Enum, values: [:CR, :GC, :UA, :RJ, :SA, :GA, :LN, :SU, :EX]
    field :link, :string
    field :reference, Ecto.UUID

    belongs_to :banking_agreement, RentReady.Banking.Agreement

    timestamps()
  end

  @doc false
  def create_changeset(requisition, attrs) do
    requisition
    |> cast(attrs, [:external_id, :status, :link, :reference])
    |> validate_required([:external_id, :status, :link, :reference])
  end

  @doc false
  def update_changeset(requisition, attrs) do
    requisition
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def from_go_cardless(%RequisitionResponse{} = remote_requisition) do
    %{
      external_id: remote_requisition.id,
      status: remote_requisition.status,
      link: remote_requisition.link,
      reference: remote_requisition.reference
    }

    # TODO: add accounts
  end
end
