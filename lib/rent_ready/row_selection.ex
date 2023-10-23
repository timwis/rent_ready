defmodule RentReady.RowSelection do
  import Ecto.Changeset

  defstruct [:selected]

  @types %{selected: :list}

  def changeset(%__MODULE__{} = row_selection, attrs) do
    {row_selection, @types}
    |> cast(attrs, [:selected])
    |> validate_required([:selected])
  end
end
