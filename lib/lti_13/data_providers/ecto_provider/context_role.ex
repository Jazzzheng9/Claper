defmodule Lti13.DataProviders.EctoProvider.ContextRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lti_13_context_roles" do
    field :uri, :string
  end

  @doc false
  def changeset(context_role, attrs \\ %{}) do
    context_role
    |> cast(attrs, [:uri])
    |> validate_required([:uri])
    |> unique_constraint(:uri)
  end
end
