defmodule RentReady.Repo.Migrations.CreateBankingInstitutions do
  use Ecto.Migration

  def change do
    create table(:banking_institutions, primary_key: [name: :id, type: :string]) do
      add :name, :string
      add :logo, :string

      timestamps()
    end
  end
end
