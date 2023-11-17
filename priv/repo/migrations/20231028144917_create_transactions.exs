defmodule RentReady.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :gc_id, :string
      add :booked_at, :date
      add :type, :string
      add :amount, :money_with_currency
      add :raw_data, :map
      add :bank_account_id, references(:bank_accounts, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:transactions, [:gc_id])
    create index(:transactions, [:bank_account_id])
  end
end
