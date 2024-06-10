defmodule Lti13.DataProviders.EctoProvider.Deployment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lti_13_deployments" do
    field :deployment_id, :string

    belongs_to :registration, Lti13.DataProviders.EctoProvider.Registration

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deployment, attrs \\ %{}) do
    deployment
    |> cast(attrs, [:deployment_id, :registration_id])
    |> validate_required([:deployment_id, :registration_id])
  end
end
