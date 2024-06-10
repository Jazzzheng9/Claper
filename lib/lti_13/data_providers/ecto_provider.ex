defmodule Lti13.DataProviders.EctoProvider do
  import Ecto.Query, warn: false

  alias Lti13.DataProviderError
  alias Lti13.Jwk
  alias Lti13.Nonce
  alias Lti13.Tool.Registration
  alias Lti13.Tool.Deployment
  alias Lti13.Platform.PlatformInstance
  alias Lti13.Platform.LoginHint

  alias Claper.Repo

  def create_jwk(%Jwk{} = jwk) do
    attrs = marshal_from(jwk)

    struct(schema(:jwk))
    |> schema(:jwk).changeset(attrs)
    |> Repo.insert()
    |> unmarshal_to(Jwk)
  end

  def get_active_jwk() do
    case Repo.all(
           from(k in schema(:jwk), where: k.active == true, order_by: [desc: k.id], limit: 1)
         ) do
      [head | _] -> {:ok, unmarshal_to(head, Jwk)}
      _ -> {:error, %{msg: "No active Jwk found", reason: :not_found}}
    end
  end

  def get_all_jwks() do
    Repo.all(from(k in schema(:jwk)))
    |> Enum.map(fn jwk -> unmarshal_to(jwk, Jwk) end)
  end

  def get_nonce(value, domain \\ nil) do
    case domain do
      nil ->
        Repo.get_by(schema(:nonce), value: value)

      domain ->
        Repo.get_by(schema(:nonce), value: value, domain: domain)
    end
    |> unmarshal_to(Nonce)
  end

  def create_nonce(%Nonce{} = nonce) do
    attrs = marshal_from(nonce)

    struct(schema(:nonce))
    |> schema(:nonce).changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, %Ecto.Changeset{errors: [value: {_msg, [{:constraint, :unique} | _]}]} = changeset} ->
        {:error,
         %Lti13.DataProviderError{
           msg: maybe_changeset_error_to_str(changeset),
           reason: :unique_constraint_violation
         }}

      nonce ->
        unmarshal_to(nonce, Nonce)
    end
  end

  # 86400 seconds = 24 hours
  def delete_expired_nonces(nonce_ttl_sec \\ 86_400) do
    nonce_expiry = Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(nonce_ttl_sec))
    Repo.delete_all(from(n in schema(:nonce), where: n.inserted_at < ^nonce_expiry))
  end

  def create_registration(%Registration{} = registration) do
    attrs = marshal_from(registration)

    struct(schema(:registration))
    |> schema(:registration).changeset(attrs)
    |> Repo.insert()
    |> unmarshal_to(Registration)
  end

  def create_deployment(%Deployment{} = deployment) do
    attrs = marshal_from(deployment)

    struct(schema(:deployment))
    |> schema(:deployment).changeset(attrs)
    |> Repo.insert()
    |> unmarshal_to(Deployment)
  end

  def get_registration_deployment(issuer, client_id, deployment_id) do
    case Repo.one(
           from(d in schema(:deployment),
             join: r in ^schema(:registration),
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
        {unmarshal_to(r, Registration), unmarshal_to(d, Deployment)}
    end
  end

  def get_jwk_by_registration(%Registration{tool_jwk_id: tool_jwk_id}) do
    Repo.one(
      from(jwk in schema(:jwk),
        where: jwk.id == ^tool_jwk_id
      )
    )
    |> unmarshal_to(Jwk)
  end

  def get_registration_by_issuer_client_id(issuer, client_id) do
    Repo.one(
      from(registration in schema(:registration),
        where: registration.issuer == ^issuer and registration.client_id == ^client_id,
        select: registration
      )
    )
    |> unmarshal_to(Registration)
  end

  def get_deployment(%Registration{id: registration_id}, deployment_id) do
    Repo.one(
      from(r in schema(:deployment),
        # where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id,
        # preload: [:registration])
        where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id
      )
    )
    |> unmarshal_to(Deployment)
  end

  def create_platform_instance(%PlatformInstance{} = platform_instance) do
    attrs = marshal_from(platform_instance)

    struct(schema(:platform_instance))
    |> schema(:platform_instance).changeset(attrs)
    |> Repo.insert()
    |> unmarshal_to(PlatformInstance)
  end

  def get_platform_instance_by_client_id(client_id),
    do:
      Repo.get_by(schema(:platform_instance), client_id: client_id)
      |> unmarshal_to(PlatformInstance)

  def get_login_hint_by_value(value),
    do:
      Repo.get_by(schema(:login_hint), value: value)
      |> unmarshal_to(LoginHint)

  def create_login_hint(%LoginHint{} = login_hint) do
    attrs = marshal_from(login_hint)

    struct(schema(:login_hint))
    |> schema(:login_hint).changeset(attrs)
    |> Repo.insert()
    |> unmarshal_to(LoginHint)
  end

  def delete_expired_login_hints(login_hint_ttl_sec \\ 86_400) do
    login_hint_expiry =
      Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(login_hint_ttl_sec))

    Repo.delete_all(from(h in schema(:login_hint), where: h.inserted_at < ^login_hint_expiry))
  end

  defp marshal_from(data) do
    Map.from_struct(data)
  end

  defp unmarshal_to({:ok, data}, struct_type) do
    map = Map.from_struct(data)
    {:ok, struct(struct_type, map)}
  end

  defp unmarshal_to({:error, maybe_changeset}, _struct_type) do
    {:error, %DataProviderError{msg: maybe_changeset_error_to_str(maybe_changeset)}}
  end

  defp unmarshal_to(nil, _struct_type) do
    nil
  end

  defp unmarshal_to(data, struct_type) do
    map = Map.from_struct(data)
    struct(struct_type, map)
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
