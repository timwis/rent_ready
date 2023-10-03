defmodule RentReady.Repo.Migrations.CreateBankingAgreements do
  use Ecto.Migration

  def change do
    create table(:banking_agreements) do
      add :external_id, :uuid
      add :expires_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      add :banking_institution_id,
          references(:banking_institutions, type: :string, on_delete: :nothing)

      timestamps()
    end

    create index(:banking_agreements, [:user_id])
    create index(:banking_agreements, [:banking_institution_id])
  end
end
