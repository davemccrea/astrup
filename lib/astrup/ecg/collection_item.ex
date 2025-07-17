defmodule Astrup.ECG.CollectionItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Astrup.ECG.Collection

  schema "ecg_collection_items" do
    field :dataset, :string
    field :filename, :string
    field :order, :integer
    belongs_to :collection, Collection

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:dataset, :filename, :collection_id]
  @optional_attrs [:order]

  @doc """
  Creates a changeset for a collection item.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(collection_item, attrs) do
    collection_item
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:dataset, min: 1, max: 100)
    |> validate_length(:filename, min: 1, max: 255)
    |> validate_number(:order, greater_than: 0)
    |> unique_constraint([:collection_id, :dataset, :filename],
      message: "ECG already exists in this collection"
    )
    |> unique_constraint(:order,
      name: :ecg_collection_items_collection_id_order_index,
      message: "Order must be unique within collection"
    )
  end
end
