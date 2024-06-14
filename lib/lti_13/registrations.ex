defmodule Lti13.Registrations do
  import Ecto.Query, warn: false
  alias Claper.Repo
  alias Lti13.Registrations.Registration

  def create_registration(attrs) do
    %Registration{}
    |> Registration.changeset(attrs)
    |> Repo.insert()
  end

  def get_registration_deployment(issuer, client_id, deployment_id) do
    case Repo.one(
           from(d in Deployment,
             join: r in Registration,
             on: d.registration_id == r.id,
             where:
               r.issuer == ^issuer and r.client_id == ^client_id and
                 d.deployment_id == ^deployment_id,
             select: {r, d}
           )
         ) do
      nil ->
        nil

      {r, d} ->
        {r, d}
    end
  end

  def get_jwk_by_registration(%Registration{tool_jwk_id: tool_jwk_id}) do
    Repo.one(
      from(jwk in Jwk,
        where: jwk.id == ^tool_jwk_id
      )
    )
  end

  def get_registration_by_issuer_client_id(issuer, client_id) do
    Repo.one(
      from(registration in Registration,
        where: registration.issuer == ^issuer and registration.client_id == ^client_id,
        select: registration
      )
    )
  end
end
