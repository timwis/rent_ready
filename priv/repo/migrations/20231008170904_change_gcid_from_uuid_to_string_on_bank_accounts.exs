defmodule RentReady.Repo.Migrations.ChangeGcidFromUuidToStringOnBankAccounts do
  use Ecto.Migration

  def change do
    alter table(:bank_accounts) do
      modify :gc_id, :string, null: false, from: :uuid
    end
  end
end
