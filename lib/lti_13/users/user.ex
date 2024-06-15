defmodule Lti13.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lti_13_users" do
    field :sub, :string
    field :name, :string
    field :email, :string
    field :roles, {:array, :string}

    belongs_to :user, Claper.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :sub,
      :name,
      :roles,
      :email,
      :user_id
    ])
    |> validate_required([:sub, :name, :email, :roles, :user_id])
    |> unique_constraint(:sub)
  end
end
