defmodule Lti13.DataProviders.EctoProvider.Repo do
  use Ecto.Repo,
    otp_app: :lti_13_ecto_provider,
    adapter: Ecto.Adapters.Postgres
end
