defmodule ClaperWeb.LtiController do
  use ClaperWeb, :controller

  alias Lti_1p3.Tool.Services.AGS
  alias Lti_1p3.Tool.Services.AGS.Score

  def bootstrap(conn, params) do
    %{"openid_configuration" => conf, "registration_token" => token} = params
    IO.inspect(conn)
    IO.inspect(params)
    render(conn, "register.html", conf: conf, token: token)
  end

  def re(conn, params) do
    {:ok, jwk} = Lti_1p3.get_active_jwk()

    %{"openid_configuration" => conf, "registration_token" => token} = params
    Finch.start_link(name: MyFinch)

    {:ok, %{body: body}} = Finch.build(:post, conf) |> Finch.request(MyFinch)

    {:ok,
     %{
       "issuer" => issuer,
       "registration_endpoint" => reg_endpoint,
       "jwks_uri" => jwks_uri,
       "authorization_endpoint" => auth_endpoint,
       "token_endpoint" => token_endpoint
     }} = body |> Jason.decode()

    IO.puts(reg_endpoint)

    {:ok, %{body: body}} =
      Finch.build(
        :post,
        reg_endpoint,
        [
          {"Authorization", "Bearer #{token}"},
          {"Content-type", "application/json"},
          {"Accept", "application/json"}
        ],
        body()
      )
      |> Finch.request(MyFinch)

    {:ok, %{"client_id" => client_id}} = body |> Jason.decode()

    # Create a Registration, Details are typically provided by the platform administrator for this registration.
    {:ok, registration} =
      Lti_1p3.Tool.create_registration(%Lti_1p3.Tool.Registration{
        issuer: issuer,
        client_id: client_id,
        key_set_url: jwks_uri,
        auth_token_url: token_endpoint,
        auth_login_url: auth_endpoint,
        auth_server: issuer,
        tool_jwk_id: jwk.id
      })

    # # Create a Deployment. Essentially this a unique identifier for a specific registration launch point,
    # # for which there can be many for a single registration. This will also typically be provided by a
    # # platform administrator.
    {:ok, _deployment} =
      Lti_1p3.Tool.create_deployment(%Lti_1p3.Tool.Deployment{
        deployment_id: "1",
        registration_id: registration.id
      })

    conn |> send_resp(200, "")
  end

  defp body() do
    Jason.encode_to_iodata!(%{
      "application_type" => "web",
      "response_types" => ["id_token"],
      "grant_types" => ["implict", "client_credentials"],
      "initiate_login_uri" => "http://localhost:4000/lti/login",
      "redirect_uris" => [
        "http://localhost:4000/lti/launch"
      ],
      "client_name" => "Claper",
      "jwks_uri" => "http://localhost:4000/.well-known/jwks.json",
      "logo_uri" => "http://localhost:4000/images/logo.svg",
      "token_endpoint_auth_method" => "private_key_jwt",
      "scope" =>
        "https://purl.imsglobal.org/spec/lti-ags/scope/score https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly",
      "https://purl.imsglobal.org/spec/lti-tool-configuration" => %{
        "domain" => "localhost:4000",
        "description" => "Claper",
        "target_link_uri" => "http://localhost:4000/lti/launch",
        "claims" => ["iss", "sub", "name", "email", "given_name", "family_name"],
        "launch_presentation_document_target" => "window"
      }
    })
  end

  def register(conn, params) do
    {:ok, jwk} = Lti_1p3.get_active_jwk()

    IO.inspect(conn)
    IO.inspect(params)

    # Create a Registration, Details are typically provided by the platform administrator for this registration.
    # {:ok, registration} =
    #   Lti_1p3.Tool.create_registration(%Lti_1p3.Tool.Registration{
    #     issuer: "http://localhost.charlesproxy.com",
    #     client_id: "NQQ8egz8Kj1s1qw",
    #     key_set_url: "http://localhost.charlesproxy.com/mod/lti/certs.php",
    #     auth_token_url: "http://localhost.charlesproxy.com/mod/lti/token.php",
    #     auth_login_url: "http://localhost.charlesproxy.com/mod/lti/auth.php",
    #     auth_server: "http://localhost.charlesproxy.com",
    #     tool_jwk_id: jwk.id
    #   })

    # # Create a Deployment. Essentially this a unique identifier for a specific registration launch point,
    # # for which there can be many for a single registration. This will also typically be provided by a
    # # platform administrator.
    # {:ok, _deployment} =
    #   Lti_1p3.Tool.create_deployment(%Lti_1p3.Tool.Deployment{
    #     deployment_id: "2",
    #     registration_id: registration.id
    #   })

    conn |> send_resp(201, "")
  end

  def grades(conn, _params) do
    resource_id = conn |> get_session(:resource_id) |> String.to_integer()
    user_id = conn |> get_session(:user_id)

    {:ok, dt} = DateTime.now("Etc/UTC")
    timestamp = DateTime.to_iso8601(dt)

    case Lti_1p3.Tool.Services.AccessToken.fetch_access_token(
           %{
             auth_token_url: "http://localhost.charlesproxy.com/mod/lti/token.php",
             client_id: "NQQ8egz8Kj1s1qw",
             auth_server: "http://localhost.charlesproxy.com"
           },
           [
             "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
             "https://purl.imsglobal.org/spec/lti-ags/scope/score"
           ],
           "http://localhost:4000"
         ) do
      {:ok, access_token} ->
        case AGS.fetch_or_create_line_item(
               "http://localhost.charlesproxy.com/mod/lti/services.php/2/lineitems?type_id=2",
               resource_id,
               fn -> 100.0 end,
               "test",
               access_token
             ) do
          {:ok, line_item} ->
            AGS.post_score(
              %Score{
                scoreGiven: 90.0,
                scoreMaximum: 100.0,
                activityProgress: "Completed",
                gradingProgress: "FullyGraded",
                userId: user_id,
                comment: "",
                timestamp: timestamp
              },
              line_item,
              access_token
            )

            conn |> send_resp(200, "")
        end

      {:error, msg} ->
        conn |> send_resp(500, msg)
    end
  end

  def login(conn, params) do
    case Lti_1p3.Tool.OidcLogin.oidc_login_redirect_url(params) do
      {:ok, state, redirect_url} ->
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
      {:ok,
       %{
         "https://purl.imsglobal.org/spec/lti/claim/context" => %{
           "label" => course_label,
           "title" => course_title
         },
         "https://purl.imsglobal.org/spec/lti/claim/resource_link" => %{
           "title" => resource_title,
           "id" => resource_id
         },
         "sub" => user_id
       } = claims} ->
        IO.inspect(claims)
        # handle_valid_lti_1p3_launch(conn, claims)
        conn = conn |> put_session(:resource_id, resource_id) |> put_session(:user_id, user_id)

        render(conn, "success.html",
          course_label: course_label,
          course_title: course_title,
          resource_title: resource_title
        )

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
    keys = Lti_1p3.get_all_public_keys()

    conn
    |> put_status(:ok)
    |> json(keys)
  end
end
