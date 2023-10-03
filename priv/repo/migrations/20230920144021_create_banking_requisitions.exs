defmodule RentReady.Repo.Migrations.CreateBankingRequisitions do
  use Ecto.Migration

  def change do
    create table(:banking_requisitions) do
      add :external_id, :uuid
      add :status, :string
      add :banking_agreement_id, references(:banking_agreements, on_delete: :nothing)
      add :link, :string

      timestamps()
    end

    create index(:banking_requisitions, [:banking_agreement_id])
  end
end
