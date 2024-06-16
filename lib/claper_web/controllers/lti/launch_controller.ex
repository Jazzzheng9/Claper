defmodule ClaperWeb.Lti.LaunchController do
  alias ClaperWeb.UserAuth
  use ClaperWeb, :controller

  def login(conn, params) do
    case Lti13.Tool.OidcLogin.oidc_login_redirect_url(params) do
      {:ok, state, redirect_url} ->
        conn
        |> put_session("state", state)
        |> redirect(external: redirect_url)

      {:error, %{reason: :invalid_registration, msg: msg, issuer: _issuer, client_id: _client_id}} ->
        render(conn, "error.html", msg: msg)

      # handle_invalid_registration(conn, issuer, client_id)

      {:error, %{reason: _reason, msg: msg}} ->
        render(conn, "error.html", msg: msg)
    end
  end

  def launch(conn, params) do
    session_state = Plug.Conn.get_session(conn, "state")

    case Lti13.Tool.LaunchValidation.validate(params, session_state) do
      {:ok,
       %{
         lti_user: lti_user,
         claims: %{
           "https://purl.imsglobal.org/spec/lti/claim/context" => %{
             "label" => _course_label,
             "title" => _course_title
           },
           "https://purl.imsglobal.org/spec/lti/claim/resource_link" => %{
             "title" => _resource_title,
             "id" => resource_id
           },
           "sub" => user_id
         }
       }} ->
        conn = conn |> put_session(:resource_id, resource_id) |> put_session(:user_id, user_id)
        UserAuth.log_in_user(conn, lti_user.user)
        redirect(conn, to: ~p"/events")

      # render(conn, "success.html",
      #   course_label: course_label,
      #   course_title: course_title,
      #   resource_title: resource_title
      # )

      {:error, %{reason: :invalid_registration, msg: msg, issuer: _issuer, client_id: _client_id}} ->
        render(conn, "error.html", msg: msg)

      {:error,
       %{
         reason: :invalid_deployment,
         msg: msg,
         registration_id: _registration_id,
         deployment_id: _deployment_id
       }} ->
        render(conn, "error.html", msg: msg)

      {:error, %{reason: _reason, msg: msg}} ->
        render(conn, "error.html", msg: msg)
    end
  end
end
