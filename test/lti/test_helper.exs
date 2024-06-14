Logger.configure(level: :warning)

ExUnit.start(exclude: [:skip])

Mix.Task.run("ecto.drop", ~w(--quiet -r Lti_1p3.DataProviders.EctoProvider.Repo))
Mix.Task.run("ecto.create", ~w(--quiet -r Lti_1p3.DataProviders.EctoProvider.Repo))
Mix.Task.run("ecto.migrate", ~w(--quiet -r Lti_1p3.DataProviders.EctoProvider.Repo))

{:ok, _pid} = Lti_1p3.DataProviders.EctoProvider.Repo.start_link()

Mix.Task.run("ecto.seed", ~w(--quiet -r Lti_1p3.DataProviders.EctoProvider.Repo))

Ecto.Adapters.SQL.Sandbox.mode(Lti_1p3.DataProviders.EctoProvider.Repo, :manual)
