defmodule RentReady.Repo.Migrations.CreateBankAccounts do
  use Ecto.Migration

  def change do
    create table(:bank_accounts) do
      add :bank_connection_id, references(:bank_connections, on_delete: :nothing)
      add :gc_id, :uuid, null: false
      add :iban, :binary
      add :name, :string
      add :type, :string

      timestamps()
    end

    create index(:bank_accounts, [:bank_connection_id])
  end
end
