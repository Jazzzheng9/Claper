defmodule Lti13.Deployments do
  import Ecto.Query, warn: false
  alias Claper.Repo
  alias Lti13.Deployments.Deployment

  def create_deployment(attrs) do
    %Deployment{}
    |> Deployment.changeset(attrs)
    |> Repo.insert()
  end

  def get_deployment(%Lti13.Registrations.Registration{id: registration_id}, deployment_id) do
    Repo.one(
      from(r in Deployment,
        where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id
      )
    )
  end
end
