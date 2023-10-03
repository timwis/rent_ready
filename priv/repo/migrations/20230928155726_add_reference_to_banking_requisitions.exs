defmodule RentReady.Repo.Migrations.AddReferenceToBankingRequisitions do
  use Ecto.Migration

  def change do
    alter table(:banking_requisitions) do
      add :reference, :uuid, comment: "GoCardless will send this on auth callback"
    end

    create index(:banking_requisitions, [:reference],
             unique: true,
             comment: "Used to lookup requisition on GoCardless auth callback"
           )
  end
end
