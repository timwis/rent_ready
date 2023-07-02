defmodule GoCardless.RelativeDateTime do
  use Ecto.Type

  def type, do: :utc_datetime

  def cast(expires_in) when is_integer(expires_in) do
    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
    {:ok, expires_at}
  end

  def cast(%DateTime{} = expires_at) do
    {:ok, expires_at}
  end

  def cast(_), do: :error

  def dump(%DateTime{} = expires_at), do: {:ok, expires_at}
  def dump(_), do: :error

  def load(%DateTime{} = expires_at), do: {:ok, expires_at}
  def load(_), do: :error
end
