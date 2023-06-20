defmodule RentReady.Repo do
  use Ecto.Repo,
    otp_app: :rent_ready,
    adapter: Ecto.Adapters.Postgres
end
