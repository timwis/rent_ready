defmodule RentReady.Repo.Migrations.AddOwnerNameToBankAccounts do
  use Ecto.Migration

  def change do
    alter table(:bank_accounts) do
      add :owner_name, :string
    end
  end
end
