defmodule Claper.Repo.Migrations.CreateOpenends do
  use Ecto.Migration

  def change do
    create table(:openends) do
      add :title, :string, null: false
      add :position, :integer, default: 0
      add :enabled, :boolean, default: true
      add :presentation_file_id, references(:presentation_files, on_delete: :nilify_all)
      add :fields, :map, default: "[]"

      timestamps()
    end
  end
end
