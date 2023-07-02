defmodule GoCardless.EndUserAgreement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :institution_id, :string
    field :created, :utc_datetime
    field :max_historical_days, :integer
    field :access_valid_for_days, :integer
    field :access_scope, {:array, Ecto.Enum}, values: [:balances, :details, :transactions]
    field :accepted, :string
  end

  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :institution_id,
      :created,
      :max_historical_days,
      :access_valid_for_days,
      :access_scope,
      :accepted
    ])
    |> apply_action!(:validate)
  end
end
