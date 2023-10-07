defmodule RentReady.Repo.Migrations.AddTransactionDaysToInstitutions do
  use Ecto.Migration

  def change do
    alter table(:institutions) do
      add :transaction_days, :integer
    end
  end
end
