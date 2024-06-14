defmodule Lti13.Nonces do
  import Ecto.Query, warn: false
  alias Claper.Repo
  alias Lti13.Nonces.Nonce

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
  def delete_expired_nonces(nonce_ttl_sec \\ 86_4000) do
    nonce_expiry = DateTime.utc_now() |> DateTime.add(-nonce_ttl_sec, :second)
    Repo.delete_all(from(n in Nonce, where: n.inserted_at < ^nonce_expiry))
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
