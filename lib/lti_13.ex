defmodule Lti13 do
  import Lti13.Config

  alias Lti13.Jwk
  alias Lti13.DataProviders.EctoProvider

  @doc """
  Creates a new jwk.
  ## Examples
      iex> create_jwk(%Jwk{})
      {:ok, %Jwk{}}
      iex> create_jwk(%Jwk{})
      {:error, %Lti13.DataProviderError{}}
  """
  def create_jwk(%Jwk{} = jwk), do: EctoProvider.create_jwk(jwk)

  @doc """
  Gets the currently active Jwk.
  If there are more that one active Jwk, this will return the first one it finds
  ## Examples
      iex> get_active_jwk()
      {:ok, %Lti13.Jwk{}}
      iex> get_active_jwk()
      {:error, %{}}
  """
  def get_active_jwk(), do: EctoProvider.get_active_jwk()

  @doc """
  Gets a all public keys.
  ## Examples
      iex> get_all_public_keys()
      %{keys: []}
  """
  def get_all_public_keys() do
    public_keys =
      EctoProvider.get_all_jwks()
      |> Enum.map(fn %{pem: pem, typ: typ, alg: alg, kid: kid} ->
        pem
        |> JOSE.JWK.from_pem()
        |> JOSE.JWK.to_public()
        |> JOSE.JWK.to_map()
        |> (fn {_kty, public_jwk} -> public_jwk end).()
        |> Map.put("typ", typ)
        |> Map.put("alg", alg)
        |> Map.put("kid", kid)
        |> Map.put("use", "sig")
      end)

    %{keys: public_keys}
  end
end
