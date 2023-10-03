Mox.defmock(MockGoCardless, for: GoCardless)
Application.put_env(:rent_ready, :go_cardless_client, MockGoCardless)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(RentReady.Repo, :manual)
