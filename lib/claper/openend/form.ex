defmodule Claper.Openend.Form do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          enabled: boolean() | nil,
          position: integer() | nil,
          title: String.t(),
          fields: [Claper.Openend.Field.t()] | nil,
          form_submits: [Claper.Openend.FormSubmit.t()] | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "openend_forms" do
    field :enabled, :boolean, default: true
    field :position, :integer, default: 0
    field :title, :string
    embeds_many :fields, Claper.Openend.Field, on_replace: :delete

    has_many :form_submits, Claper.Openend.FormSubmit, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:enabled, :title, :position])
    |> cast_embed(:fields)
    |> validate_required([:title, :position])
  end
end
