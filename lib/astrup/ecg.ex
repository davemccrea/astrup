defmodule Astrup.ECG do
  alias Astrup.Repo
  alias Astrup.Accounts.User
  alias Astrup.Accounts.Scope
  alias Astrup.ECG.SavedEcgs
  alias Astrup.ECG.Collection
  alias Astrup.ECG.CollectionItem

  import Ecto.Query

  def save_ecg(%Scope{user: %User{id: user_id}}, attrs) do
    %SavedEcgs{}
    |> SavedEcgs.changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  def get_users_saved_ecgs(%Scope{user: %User{id: user_id}}) do
    Repo.all(from(s in SavedEcgs, where: s.user_id == ^user_id))
  end

  def is_ecg_saved?(%Scope{user: %User{id: user_id}}, dataset_name, filename) do
    query =
      from(s in SavedEcgs,
        where: s.user_id == ^user_id and s.db_name == ^dataset_name and s.filename == ^filename
      )

    Repo.exists?(query)
  end

  def unsave_ecg(%Scope{user: %User{id: user_id}}, dataset_name, filename) do
    query =
      from(s in SavedEcgs,
        where: s.user_id == ^user_id and s.db_name == ^dataset_name and s.filename == ^filename
      )

    Repo.delete_all(query)
  end

  def delete_saved_ecg(%Scope{user: %User{id: user_id}}, ecg_id) do
    query =
      from(s in SavedEcgs,
        where: s.user_id == ^user_id and s.id == ^ecg_id
      )

    Repo.delete_all(query)
  end

  # Collection functions

  def list_collections do
    Repo.all(Collection)
  end

  def get_collection(id) do
    Repo.get(Collection, id)
  end

  def get_collection_by_slug(slug) do
    Repo.get_by(Collection, slug: slug)
  end

  def get_collection_with_items(id) do
    Collection
    |> Repo.get(id)
    |> case do
      nil -> nil
      collection -> Repo.preload(collection, collection_items: from(ci in CollectionItem, order_by: [asc: coalesce(ci.order, ci.id)]))
    end
  end

  def create_collection(attrs) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  # CollectionItem functions

  def get_collection_item(id) do
    Repo.get(CollectionItem, id)
  end

  def add_ecg_to_collection(collection_id, attrs) do
    %CollectionItem{}
    |> CollectionItem.changeset(Map.put(attrs, :collection_id, collection_id))
    |> Repo.insert()
  end

  def update_collection_item(%CollectionItem{} = collection_item, attrs) do
    collection_item
    |> CollectionItem.changeset(attrs)
    |> Repo.update()
  end

  def remove_ecg_from_collection(%CollectionItem{} = collection_item) do
    Repo.delete(collection_item)
  end
end
