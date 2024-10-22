defmodule Claper.Repo.Migrations.CreateOpenendSubmits do
  use Ecto.Migration

  def change do
    create table(:openend_submits) do
      add :attendee_identifier, :string
      add :openend_id, references(:openends, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :response, :map, default: "[]"

      timestamps()
    end

    create index(:openend_submits, [:openend_id, :user_id])
    create index(:openend_submits, [:openend_id, :attendee_identifier])
  end
end
