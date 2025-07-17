defmodule Astrup.ECG.CollectionTest do
  use Astrup.DataCase, async: true

  alias Astrup.ECG.Collection

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "Basic ECG Rhythms",
        slug: "basic-ecg-rhythms"
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      assert changeset.valid?
      assert changeset.changes.name == "Basic ECG Rhythms"
      assert changeset.changes.slug == "basic-ecg-rhythms"
    end

    test "valid changeset with optional description" do
      attrs = %{
        name: "Advanced ECG Patterns",
        slug: "advanced-ecg-patterns",
        description: "A comprehensive collection of advanced ECG patterns"
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      assert changeset.valid?

      assert changeset.changes.description ==
               "A comprehensive collection of advanced ECG patterns"
    end

    test "invalid changeset missing required name" do
      attrs = %{slug: "test-slug"}

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset missing required slug" do
      attrs = %{name: "Test Collection"}

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?
      assert %{slug: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset with name too long" do
      attrs = %{
        name: String.duplicate("a", 101),
        slug: "test-slug"
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "invalid changeset with description too long" do
      attrs = %{
        name: "Test Collection",
        slug: "test-slug",
        description: String.duplicate("a", 501)
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?
      assert %{description: ["should be at most 500 character(s)"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid slug format" do
      attrs = %{
        name: "Test Collection",
        slug: "Invalid Slug With Spaces"
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?

      assert %{slug: ["must contain only lowercase letters, numbers, and hyphens"]} =
               errors_on(changeset)
    end

    test "invalid changeset with slug too long" do
      attrs = %{
        name: "Test Collection",
        slug: String.duplicate("a", 101)
      }

      changeset = Collection.changeset(%Collection{}, attrs)

      refute changeset.valid?
      assert %{slug: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "valid slug formats" do
      valid_slugs = [
        "basic-ecg",
        "advanced-patterns-123",
        "test123",
        "single",
        "a-b-c-d-e-f-g-h-i-j-k-l-m-n-o-p-q-r-s-t-u-v-w-x-y-z"
      ]

      for slug <- valid_slugs do
        attrs = %{name: "Test", slug: slug}
        changeset = Collection.changeset(%Collection{}, attrs)
        assert changeset.valid?, "Expected '#{slug}' to be valid"
      end
    end
  end
end
