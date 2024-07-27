import Config
import Claper.ConfigHelpers

config_dir = System.get_env("CONFIG_DIR", "/run/secrets")

database_url =
  get_var_from_path_or_env(
    config_dir,
    "DATABASE_URL",
    "postgres://claper:claper@localhost:5432/postgres"
  )

db_ssl = get_var_from_path_or_env(config_dir, "DB_SSL", "false") |> String.to_existing_atom()

# Listen IP supports IPv4 and IPv6 addresses.
listen_ip =
  (
    str = get_var_from_path_or_env(config_dir, "LISTEN_IP") || "0.0.0.0"

    case :inet.parse_address(String.to_charlist(str)) do
      {:ok, ip_addr} ->
        ip_addr

      {:error, reason} ->
        raise "Invalid LISTEN_IP '#{str}' error: #{inspect(reason)}"
    end
  )

port = get_int_from_path_or_env(config_dir, "PORT", "4000")

secret_key_base = get_var_from_path_or_env(config_dir, "SECRET_KEY_BASE", nil)

case secret_key_base do
  nil ->
    raise "SECRET_KEY_BASE configuration option is required. See https://docs.claper.co/configuration.html#production-docker"

  key when byte_size(key) < 32 ->
    raise "SECRET_KEY_BASE must be at least 32 bytes long. See https://docs.claper.co/configuration.html#production-docker"

  _ ->
    nil
end

site_url = get_var_from_path_or_env(config_dir, "SITE_URL", "http://localhost:4000")
base_url = get_var_from_path_or_env(config_dir, "BASE_URL")

if !base_url do
  raise "BASE_URL configuration option is required. See https://docs.claper.co/configuration.html#production-docker"
end

base_url = URI.parse(base_url)

if base_url.scheme not in ["http", "https"] do
  raise "BASE_URL must start with `http` or `https`. Currently configured as `#{System.get_env("BASE_URL")}`"
end

max_file_size = get_int_from_path_or_env(config_dir, "MAX_FILE_SIZE_MB", 15)

enable_account_creation =
  get_var_from_path_or_env(config_dir, "ENABLE_ACCOUNT_CREATION", "true")
  |> String.to_existing_atom()

pool_size = get_int_from_path_or_env(config_dir, "POOL_SIZE", 10)
queue_target = get_int_from_path_or_env(config_dir, "QUEUE_TARGET", 5_000)

mail_transport = get_var_from_path_or_env(config_dir, "MAIL_TRANSPORT", "local")

smtp_relay = get_var_from_path_or_env(config_dir, "SMTP_RELAY", nil)
smtp_username = get_var_from_path_or_env(config_dir, "SMTP_USERNAME", nil)
smtp_password = get_var_from_path_or_env(config_dir, "SMTP_PASSWORD", nil)
smtp_ssl = get_var_from_path_or_env(config_dir, "SMTP_SSL", "true") |> String.to_existing_atom()
smtp_tls = get_var_from_path_or_env(config_dir, "SMTP_TLS", "always")
smtp_auth = get_var_from_path_or_env(config_dir, "SMTP_AUTH", "always")
smtp_port = get_int_from_path_or_env(config_dir, "SMTP_PORT", 25)

aws_access_key_id = get_var_from_path_or_env(config_dir, "AWS_ACCESS_KEY_ID", nil)
aws_secret_access_key = get_var_from_path_or_env(config_dir, "AWS_SECRET_ACCESS_KEY", nil)
aws_region = get_var_from_path_or_env(config_dir, "AWS_REGION", nil)

same_site_cookie = get_var_from_path_or_env(config_dir, "SAME_SITE_COOKIE", "Lax")

secure_cookie =
  get_var_from_path_or_env(config_dir, "SECURE_COOKIE", "false") |> String.to_existing_atom()

oidc_issuer = get_var_from_path_or_env(config_dir, "OIDC_ISSUER", "https://accounts.google.com")

oidc_discovery_document_uri =
  get_var_from_path_or_env(
    config_dir,
    "OIDC_DISCOVERY_DOCUMENT_URI",
    "https://accounts.google.com/.well-known/openid-configuration"
  )

oidc_client_id = get_var_from_path_or_env(config_dir, "OIDC_CLIENT_ID", nil)
oidc_client_secret = get_var_from_path_or_env(config_dir, "OIDC_CLIENT_SECRET", nil)
oidc_redirect_uri = get_var_from_path_or_env(config_dir, "OIDC_REDIRECT_URI", nil)
oidc_response_type = get_var_from_path_or_env(config_dir, "OIDC_RESPONSE_TYPE", "code")
oidc_scope = get_var_from_path_or_env(config_dir, "OIDC_SCOPE", "openid email profile")

config :claper, :oidc,
  issuer: oidc_issuer,
  discovery_document_uri: oidc_discovery_document_uri,
  client_id: oidc_client_id,
  client_secret: oidc_client_secret,
  redirect_uri: oidc_redirect_uri,
  response_type: oidc_response_type,
  scope: oidc_scope

config :claper, Claper.Repo,
  url: database_url,
  ssl: db_ssl,
  ssl_opts: [
    verify: :verify_none
  ],
  prepare: :unnamed,
  pool_size: pool_size,
  queue_target: queue_target

config :claper, ClaperWeb.Endpoint,
  url: [scheme: base_url.scheme, host: base_url.host, path: base_url.path, port: base_url.port],
  http: [
    ip: listen_ip,
    port: port,
    transport_options: [max_connections: :infinity],
    protocol_options: [max_request_line_length: 8192, max_header_value_length: 8192]
  ],
  secret_key_base: secret_key_base,
  same_site_cookie: same_site_cookie,
  secure_cookie: secure_cookie

config :claper,
  enable_account_creation: enable_account_creation

config :claper, :presentations,
  max_file_size: max_file_size,
  storage: get_var_from_path_or_env(config_dir, "PRESENTATION_STORAGE", "local"),
  aws_bucket: get_var_from_path_or_env(config_dir, "AWS_PRES_BUCKET", nil),
  resolution: get_var_from_path_or_env(config_dir, "GS_JPG_RESOLUTION", "300x300")

config :claper, :mail,
  from: get_var_from_path_or_env(config_dir, "MAIL_FROM", "noreply@claper.co"),
  from_name: get_var_from_path_or_env(config_dir, "MAIL_FROM_NAME", "Claper")

config :claper, ClaperWeb.MailboxGuard,
  username: get_var_from_path_or_env(config_dir, "MAILBOX_USER", nil),
  password: get_var_from_path_or_env(config_dir, "MAILBOX_PASSWORD", nil),
  enabled:
    get_var_from_path_or_env(config_dir, "ENABLE_MAILBOX_ROUTE", "false")
    |> String.to_existing_atom()

case mail_transport do
  "smtp" ->
    config :claper, Claper.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_relay,
      username: smtp_username,
      password: smtp_password,
      ssl: smtp_ssl,
      # always, never, if_available
      tls: smtp_tls,
      # always, never, if_available
      auth: smtp_auth,
      port: smtp_port

    config :swoosh, :api_client, false

  "postmark" ->
    config :claper, Claper.Mailer,
      adapter: Swoosh.Adapters.Postmark,
      api_key: get_var_from_path_or_env(config_dir, "POSTMARK_API_KEY", nil)

    config :swoosh, :api_client, Swoosh.ApiClient.Hackney

  _ ->
    config :claper, Claper.Mailer, adapter: Swoosh.Adapters.Local
    config :swoosh, :api_client, false
end

config :ex_aws,
  access_key_id: aws_access_key_id,
  secret_access_key: aws_secret_access_key,
  region: aws_region,
  normalize_path: false

config :swoosh, :api_client, Swoosh.ApiClient.Finch
