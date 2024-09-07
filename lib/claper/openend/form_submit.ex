defmodule Claper.Openend.FormSubmit do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          attendee_identifier: String.t() | nil,
          response: map(),
          form_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "openend_form_submits" do
    field :attendee_identifier, :string
    field :response, :map, on_replace: :delete
    belongs_to :form, Claper.Openend.Form

    timestamps()
  end

  @doc false
  def changeset(form_submit, attrs) do
    form_submit
    |> cast(attrs, [:attendee_identifier, :form_id, :response])
    |> validate_required([:form_id])
  end
end
