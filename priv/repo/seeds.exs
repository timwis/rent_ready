# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RentReady.Repo.insert!(%RentReady.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias RentReady.Repo
alias RentReady.Banking.Institution

Repo.insert!(
  %Institution{
    id: "SANDBOXFINANCE_SFIN0000",
    name: "Sandbox Finance",
    logo: "https://cdn.nordigen.com/ais/SANDBOXFINANCE_SFIN0000.png",
    transaction_days: 90
  },
  on_conflict: :nothing
)
