defmodule RentReady.Repo.Migrations.ReplaceAgreementsAndRequisitionsWithBankConnections do
  use Ecto.Migration

  def change do
    rename table(:banking_institutions), to: table(:institutions)

    create table(:bank_connections) do
      add :user_id, references(:users, on_delete: :nothing)

      add :institution_id,
          references(:institutions, type: :string, on_delete: :nothing)

      add :gc_agreement_id, :uuid
      add :gc_requisition_id, :uuid
      add :reference, :uuid, comment: "GoCardless will send this on auth callback"
      add :link, :string
      add :status, :string
      add :expires_at, :utc_datetime

      timestamps()
    end

    create index(:bank_connections, [:user_id])
    create index(:bank_connections, [:institution_id])

    create index(:bank_connections, [:reference],
             unique: true,
             comment: "Used to lookup requisition on GoCardless auth callback"
           )

    drop table(:banking_requisitions)
    drop table(:banking_agreements)
  end
end
