defmodule Lti13.DataProviders.EctoProvider.PlatformRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lti_13_platform_roles" do
    field :uri, :string
  end

  @doc false
  def changeset(platform_role, attrs \\ %{}) do
    platform_role
    |> cast(attrs, [:uri])
    |> validate_required([:uri])
    |> unique_constraint(:uri)
  end
end
