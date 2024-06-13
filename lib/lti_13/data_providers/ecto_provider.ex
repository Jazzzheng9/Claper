defmodule Lti13.DataProviders.EctoProvider do
  import Ecto.Query, warn: false

  alias Lti13.DataProviders.EctoProvider.Jwk
  alias Lti13.DataProviders.EctoProvider.Nonce
  alias Lti13.DataProviders.EctoProvider.Registration
  alias Lti13.DataProviders.EctoProvider.Deployment
  alias Lti13.DataProviders.EctoProvider.PlatformInstance
  alias Lti13.DataProviders.EctoProvider.LoginHint

  alias Claper.Repo

  def create_jwk(attrs) do
    %Jwk{}
    |> Jwk.changeset(attrs)
    |> Repo.insert()
  end

  def get_active_jwk() do
    case Repo.all(from(k in Jwk, where: k.active == true, order_by: [desc: k.id], limit: 1)) do
      [head | _] -> head
      _ -> {:error, %{msg: "No active Jwk found", reason: :not_found}}
    end
  end

  def get_all_jwks() do
    Repo.all(from(k in Jwk))
  end

  def get_nonce(value, domain \\ nil) do
    case domain do
      nil ->
        Repo.get_by(Nonce, value: value)

      domain ->
        Repo.get_by(Nonce, value: value, domain: domain)
    end
  end

  def create_nonce(attrs) do
    %Nonce{}
    |> Nonce.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, %Ecto.Changeset{errors: [value: {_msg, [{:constraint, :unique} | _]}]} = changeset} ->
        {:error,
         %{
           msg: maybe_changeset_error_to_str(changeset),
           reason: :unique_constraint_violation
         }}

      nonce ->
        nonce
    end
  end

  # 86400 seconds = 24 hours
  def delete_expired_nonces(nonce_ttl_sec \\ 86_400) do
    nonce_expiry = Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(nonce_ttl_sec))
    Repo.delete_all(from(n in Nonce, where: n.inserted_at < ^nonce_expiry))
  end

  def create_registration(attrs) do
    %Registration{}
    |> Registration.changeset(attrs)
    |> Repo.insert()
  end

  def create_deployment(attrs) do
    %Deployment{}
    |> Deployment.changeset(attrs)
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

  def get_deployment(%Registration{id: registration_id}, deployment_id) do
    Repo.one(
      from(r in Deployment,
        # where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id,
        # preload: [:registration])
        where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id
      )
    )
  end

  def create_platform_instance(attrs) do
    %PlatformInstance{}
    |> PlatformInstance.changeset(attrs)
    |> Repo.insert()
  end

  def get_platform_instance_by_client_id(client_id),
    do: Repo.get_by(PlatformInstance, client_id: client_id)

  def get_login_hint_by_value(value),
    do: Repo.get_by(LoginHint, value: value)

  def create_login_hint(attrs) do
    %LoginHint{}
    |> LoginHint.changeset(attrs)
    |> Repo.insert()
  end

  def delete_expired_login_hints(login_hint_ttl_sec \\ 86_400) do
    login_hint_expiry =
      Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(login_hint_ttl_sec))

    Repo.delete_all(from(h in LoginHint, where: h.inserted_at < ^login_hint_expiry))
  end

  defp maybe_changeset_error_to_str(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", _to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc} #{k}: #{joined_errors}"
    end)
    |> String.trim()
  end

  defp maybe_changeset_error_to_str(no_changeset), do: no_changeset

  defp _to_string(val) when is_list(val) do
    Enum.join(val, ",")
  end

  defp _to_string(val), do: to_string(val)
end
