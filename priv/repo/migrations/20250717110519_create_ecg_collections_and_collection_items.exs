defmodule Astrup.Repo.Migrations.CreateEcgCollectionsAndCollectionItems do
  use Ecto.Migration

  def change do
    create table(:ecg_collections) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ecg_collections, [:name])
    create unique_index(:ecg_collections, [:slug])

    create table(:ecg_collection_items) do
      add :dataset, :string, null: false
      add :filename, :string, null: false
      add :order, :integer
      add :collection_id, references(:ecg_collections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ecg_collection_items, [:collection_id, :dataset, :filename])
    create unique_index(:ecg_collection_items, [:collection_id, :order])
    create index(:ecg_collection_items, [:collection_id])
  end
end
