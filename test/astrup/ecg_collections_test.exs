defmodule Astrup.ECGCollectionsTest do
  use Astrup.DataCase, async: true

  alias Astrup.ECG
  alias Astrup.ECG.{Collection, CollectionItem}

  describe "list_collections/0" do
    test "returns empty list when no collections exist" do
      assert ECG.list_collections() == []
    end

    test "returns all collections" do
      collection1 = collection_fixture(%{name: "Collection 1", slug: "collection-1"})
      collection2 = collection_fixture(%{name: "Collection 2", slug: "collection-2"})

      collections = ECG.list_collections()

      assert length(collections) == 2
      assert Enum.find(collections, &(&1.id == collection1.id))
      assert Enum.find(collections, &(&1.id == collection2.id))
    end
  end

  describe "get_collection/1" do
    test "returns collection when it exists" do
      collection = collection_fixture()

      assert ECG.get_collection(collection.id) == collection
    end

    test "returns nil when collection doesn't exist" do
      assert ECG.get_collection(999) == nil
    end
  end

  describe "get_collection_by_slug/1" do
    test "returns collection when it exists" do
      collection = collection_fixture(%{slug: "test-collection"})

      assert ECG.get_collection_by_slug("test-collection") == collection
    end

    test "returns nil when collection doesn't exist" do
      assert ECG.get_collection_by_slug("nonexistent") == nil
    end
  end

  describe "get_collection_with_items/1" do
    test "returns collection with items ordered by order field" do
      collection = collection_fixture()

      item1 = collection_item_fixture(%{collection_id: collection.id, order: 2})
      item2 = collection_item_fixture(%{collection_id: collection.id, order: 1})
      item3 = collection_item_fixture(%{collection_id: collection.id, order: 3})

      result = ECG.get_collection_with_items(collection.id)

      assert result.id == collection.id
      assert length(result.collection_items) == 3
      assert Enum.map(result.collection_items, & &1.id) == [item2.id, item1.id, item3.id]
    end

    test "returns collection with items ordered by id when no order specified" do
      collection = collection_fixture()

      item1 = collection_item_fixture(%{collection_id: collection.id})
      item2 = collection_item_fixture(%{collection_id: collection.id})

      result = ECG.get_collection_with_items(collection.id)

      assert result.id == collection.id
      assert length(result.collection_items) == 2
      assert Enum.map(result.collection_items, & &1.id) == [item1.id, item2.id]
    end

    test "returns nil when collection doesn't exist" do
      assert ECG.get_collection_with_items(999) == nil
    end
  end

  describe "create_collection/1" do
    test "creates collection with valid attributes" do
      attrs = %{
        name: "Test Collection",
        slug: "test-collection",
        description: "A test collection"
      }

      assert {:ok, collection} = ECG.create_collection(attrs)
      assert collection.name == "Test Collection"
      assert collection.slug == "test-collection"
      assert collection.description == "A test collection"
    end

    test "returns error with invalid attributes" do
      attrs = %{name: ""}

      assert {:error, changeset} = ECG.create_collection(attrs)
      assert %{name: ["can't be blank"], slug: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_collection/2" do
    test "updates collection with valid attributes" do
      collection = collection_fixture()
      attrs = %{name: "Updated Name", description: "Updated description"}

      assert {:ok, updated_collection} = ECG.update_collection(collection, attrs)
      assert updated_collection.name == "Updated Name"
      assert updated_collection.description == "Updated description"
    end

    test "returns error with invalid attributes" do
      collection = collection_fixture()
      attrs = %{name: ""}

      assert {:error, changeset} = ECG.update_collection(collection, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_collection/1" do
    test "deletes collection" do
      collection = collection_fixture()

      assert {:ok, _deleted} = ECG.delete_collection(collection)
      assert ECG.get_collection(collection.id) == nil
    end
  end

  describe "get_collection_item/1" do
    test "returns collection item when it exists" do
      collection = collection_fixture()
      item = collection_item_fixture(%{collection_id: collection.id})

      assert ECG.get_collection_item(item.id) == item
    end

    test "returns nil when collection item doesn't exist" do
      assert ECG.get_collection_item(999) == nil
    end
  end

  describe "add_ecg_to_collection/2" do
    test "adds ECG to collection with valid attributes" do
      collection = collection_fixture()

      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        order: 1
      }

      assert {:ok, item} = ECG.add_ecg_to_collection(collection.id, attrs)
      assert item.dataset == "ptbxl"
      assert item.filename == "record001.hea"
      assert item.order == 1
      assert item.collection_id == collection.id
    end

    test "returns error with invalid attributes" do
      collection = collection_fixture()
      attrs = %{dataset: ""}

      assert {:error, changeset} = ECG.add_ecg_to_collection(collection.id, attrs)
      assert %{dataset: ["can't be blank"], filename: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_collection_item/2" do
    test "updates collection item with valid attributes" do
      collection = collection_fixture()
      item = collection_item_fixture(%{collection_id: collection.id})
      attrs = %{order: 5}

      assert {:ok, updated_item} = ECG.update_collection_item(item, attrs)
      assert updated_item.order == 5
    end

    test "returns error with invalid attributes" do
      collection = collection_fixture()
      item = collection_item_fixture(%{collection_id: collection.id})
      attrs = %{filename: ""}

      assert {:error, changeset} = ECG.update_collection_item(item, attrs)
      assert %{filename: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "remove_ecg_from_collection/1" do
    test "removes ECG from collection" do
      collection = collection_fixture()
      item = collection_item_fixture(%{collection_id: collection.id})

      assert {:ok, _deleted} = ECG.remove_ecg_from_collection(item)
      assert ECG.get_collection_item(item.id) == nil
    end
  end

  # Test helpers

  defp collection_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Collection",
      slug: "test-collection-#{System.unique_integer([:positive])}"
    }

    {:ok, collection} =
      default_attrs
      |> Map.merge(attrs)
      |> ECG.create_collection()

    collection
  end

  defp collection_item_fixture(attrs \\ %{}) do
    collection =
      case Map.get(attrs, :collection_id) do
        nil -> collection_fixture()
        _ -> nil
      end

    default_attrs = %{
      dataset: "ptbxl",
      filename: "record#{System.unique_integer([:positive])}.hea",
      collection_id: collection && collection.id
    }

    {:ok, item} =
      default_attrs
      |> Map.merge(attrs)
      |> then(&ECG.add_ecg_to_collection(&1.collection_id, Map.delete(&1, :collection_id)))

    item
  end
end
