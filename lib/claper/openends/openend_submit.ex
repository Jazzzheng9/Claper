defmodule Claper.Openends.OpenendSubmit do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          attendee_identifier: String.t() | nil,
          response: map(),
          openend_id: integer() | nil,
          user_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "openend_submits" do
    field :attendee_identifier, :string
    field :response, :map, on_replace: :delete
    belongs_to :openend, Claper.Openends.Openend
    belongs_to :user, Claper.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(openend_submit, attrs) do
    openend_submit
    |> cast(attrs, [:attendee_identifier, :openend_id, :response])
    |> validate_required([:openend_id])
  end
end
