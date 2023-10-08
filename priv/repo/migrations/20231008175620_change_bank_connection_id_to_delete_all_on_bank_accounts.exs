defmodule RentReady.Repo.Migrations.ChangeBankConnectionIdToDeleteAllOnBankAccounts do
  use Ecto.Migration

  def change do
    alter table(:bank_accounts) do
      modify :bank_connection_id, references(:bank_connections, on_delete: :delete_all),
        from: references(:bank_connections, on_delete: :nothing)
    end
  end
end
