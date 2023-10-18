defmodule RentReady.Repo.Migrations.AddGcResourceIdAndChangeGcIdBackToUuidOnBankAccounts do
  use Ecto.Migration

  def change do
    alter table(:bank_accounts) do
      remove :gc_id

      add :gc_id, :uuid, null: false
      add :gc_resource_id, :binary, comment: "The id of the account in the financial institution"
    end
  end
end
