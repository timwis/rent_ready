defmodule GoCardless.RequisitionResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :created, :utc_datetime
    field :redirect, :string
    field :status, :string
    field :institution_id, :string
    field :agreement, :string
    field :reference, :string
    field :acccounts, {:array, :string}
    field :link, :string
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :id,
      :created,
      :redirect,
      :status,
      :institution_id,
      :agreement,
      :reference,
      :accounts,
      :link
    ])
    |> apply_action!(:validate)
  end
end
