defmodule Claper.Openend.Field do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          answer: String.t()
        }

  @primary_key false
  embedded_schema do
    field :answer, :string
  end

  @doc false
  def changeset(field, attrs \\ %{}) do
    field
    |> cast(attrs, [:answer])
    |> validate_required([:answer])
  end
end
