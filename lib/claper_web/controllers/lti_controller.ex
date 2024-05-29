defmodule ClaperWeb.LtiController do
  use ClaperWeb, :controller

  def register(conn, _params) do
    # this jwk is the same jwk we generated in the section above
    {:ok, jwk} = Lti_1p3.get_active_jwk()

    # Create a Registration, Details are typically provided by the platform administrator for this registration.
    {:ok, registration} =
      Lti_1p3.Tool.create_registration(%Lti_1p3.Tool.Registration{
        issuer: "http://localhost",
        client_id: "NQQ8egz8Kj1s1qw",
        key_set_url: "http://localhost/mod/lti/certs.php",
        auth_token_url: "http://localhost/mod/lti/token.php",
        auth_login_url: "http://localhost/mod/lti/auth.php",
        auth_server: "http://localhost",
        tool_jwk_id: jwk.id
      })

    # Create a Deployment. Essentially this a unique identifier for a specific registration launch point,
    # for which there can be many for a single registration. This will also typically be provided by a
    # platform administrator.
    {:ok, _deployment} =
      Lti_1p3.Tool.create_deployment(%Lti_1p3.Tool.Deployment{
        deployment_id: "2",
        registration_id: registration.id
      })

    conn |> send_resp(201, "")
  end

  def login(conn, params) do
    case Lti_1p3.Tool.OidcLogin.oidc_login_redirect_url(params) do
      {:ok, state, redirect_url} ->
        IO.puts(redirect_url)

        conn
        |> put_session("state", state)
        |> redirect(external: redirect_url)

      {:error, %{reason: :invalid_registration, msg: msg, issuer: issuer, client_id: client_id}} ->
        render(conn, "error.html", msg: msg)

      # handle_invalid_registration(conn, issuer, client_id)

      {:error, %{reason: _reason, msg: msg}} ->
        render(conn, "error.html", msg: msg)
    end
  end

  def launch(conn, params) do
    session_state = Plug.Conn.get_session(conn, "state")

    case Lti_1p3.Tool.LaunchValidation.validate(params, session_state) do
      {:ok, claims} ->
        # handle_valid_lti_1p3_launch(conn, claims)
        render(conn, "success.html", msg: claims)

      {:error, %{reason: :invalid_registration, msg: msg, issuer: issuer, client_id: client_id}} ->
        # handle_invalid_registration(conn, issuer, client_id)
        render(conn, "error.html", msg: msg)

      {:error,
       %{
         reason: :invalid_deployment,
         msg: msg,
         registration_id: registration_id,
         deployment_id: deployment_id
       }} ->
        # handle_invalid_deployment(conn, registration_id, deployment_id)
        render(conn, "error.html", msg: msg)

      {:error, %{reason: _reason, msg: msg}} ->
        render(conn, "error.html", msg: msg)
    end
  end

  def jwks(conn, _params) do
    Lti_1p3.get_active_jwk() |> store_key()

    keys = Lti_1p3.get_all_public_keys()

    conn
    |> put_status(:ok)
    |> json(keys)
  end

  defp store_key({:error, _}) do
    {:ok, private_key} = File.read(Path.join(:code.priv_dir(:claper), "data/lti.key"))

    {:ok, jwk} =
      Lti_1p3.create_jwk(%Lti_1p3.Jwk{
        pem: private_key,
        typ: "JWT",
        alg: "RS256",
        kid: "BD02B7F2-01BE-4058-99F2-3BE9A7969107",
        active: true
      })
  end

  defp store_key(_), do: nil
end
