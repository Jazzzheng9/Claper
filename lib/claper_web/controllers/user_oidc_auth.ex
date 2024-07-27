defmodule ClaperWeb.UserOidcAuth do
  @moduledoc """
    Plug for OpenID Connect authentication.
  """
  use ClaperWeb, :controller

  import Phoenix.Controller

  def config do
    Application.get_env(:claper, :oidc)
  end

  def client_id do
    config()[:client_id]
  end

  def client_secret do
    config()[:client_secret]
  end

  @doc false
  def new(conn, _params) do
    {:ok, redirect_uri} =
      Oidcc.create_redirect_url(
        Claper.OidcProviderConfig,
        client_id(),
        client_secret(),
        %{redirect_uri: "http://localhost:4000/users/oidc/callback"}
      )

    uri = Enum.join(redirect_uri, "")

    redirect(conn, external: uri)
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:info, "User created successfully.")
    |> redirect(to: ~p"/")
  end
end
