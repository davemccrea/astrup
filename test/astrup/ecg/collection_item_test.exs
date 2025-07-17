defmodule Astrup.ECG.CollectionItemTest do
  use Astrup.DataCase, async: true

  alias Astrup.ECG.{Collection, CollectionItem}

  setup do
    {:ok, collection} =
      %Collection{}
      |> Collection.changeset(%{name: "Test Collection", slug: "test-collection"})
      |> Repo.insert()

    %{collection: collection}
  end

  describe "changeset/2" do
    test "valid changeset with required fields", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        collection_id: collection.id
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      assert changeset.valid?
      assert changeset.changes.dataset == "ptbxl"
      assert changeset.changes.filename == "record001.hea"
      assert changeset.changes.collection_id == collection.id
    end

    test "valid changeset with optional order", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        collection_id: collection.id,
        order: 1
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      assert changeset.valid?
      assert changeset.changes.order == 1
    end

    test "invalid changeset missing required dataset", %{collection: collection} do
      attrs = %{
        filename: "record001.hea",
        collection_id: collection.id
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{dataset: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset missing required filename", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        collection_id: collection.id
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{filename: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset missing required collection_id" do
      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea"
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{collection_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset with dataset too long", %{collection: collection} do
      attrs = %{
        dataset: String.duplicate("a", 101),
        filename: "record001.hea",
        collection_id: collection.id
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{dataset: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "invalid changeset with filename too long", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        filename: String.duplicate("a", 256),
        collection_id: collection.id
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{filename: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end

    test "invalid changeset with order less than or equal to 0", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        collection_id: collection.id,
        order: 0
      }

      changeset = CollectionItem.changeset(%CollectionItem{}, attrs)

      refute changeset.valid?
      assert %{order: ["must be greater than 0"]} = errors_on(changeset)
    end
  end

  describe "database constraints" do
    test "unique constraint on collection_id, dataset, filename", %{collection: collection} do
      attrs = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        collection_id: collection.id
      }

      # Insert first item
      {:ok, _item1} =
        %CollectionItem{}
        |> CollectionItem.changeset(attrs)
        |> Repo.insert()

      # Try to insert duplicate
      assert {:error, changeset} =
               %CollectionItem{}
               |> CollectionItem.changeset(attrs)
               |> Repo.insert()

      assert %{collection_id: ["ECG already exists in this collection"]} = errors_on(changeset)
    end

    test "unique constraint on collection_id, order", %{collection: collection} do
      attrs1 = %{
        dataset: "ptbxl",
        filename: "record001.hea",
        collection_id: collection.id,
        order: 1
      }

      attrs2 = %{
        dataset: "ptbxl",
        filename: "record002.hea",
        collection_id: collection.id,
        order: 1
      }

      # Insert first item
      {:ok, _item1} =
        %CollectionItem{}
        |> CollectionItem.changeset(attrs1)
        |> Repo.insert()

      # Try to insert item with same order
      assert {:error, changeset} =
               %CollectionItem{}
               |> CollectionItem.changeset(attrs2)
               |> Repo.insert()

      assert %{order: ["Order must be unique within collection"]} = errors_on(changeset)
    end
  end
end
