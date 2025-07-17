defmodule Astrup.ECG.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  alias Astrup.ECG.CollectionItem

  schema "ecg_collections" do
    field :name, :string
    field :description, :string
    field :slug, :string
    has_many :collection_items, CollectionItem

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:name, :slug]
  @optional_attrs [:description]

  @doc """
  Creates a changeset for a collection.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:slug, min: 1, max: 100)
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
