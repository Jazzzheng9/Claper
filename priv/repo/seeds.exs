# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Claper.Repo.insert!(%Claper.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# create a default active lti_1p3 jwk
if !Claper.Repo.get_by(Lti13.DataProviders.EctoProvider.Jwk, id: 1) do
  %{private_key: private_key} = Lti13.KeyGenerator.generate_key_pair()

  Lti13.create_jwk(%{
    pem: private_key,
    typ: "JWT",
    alg: "RS256",
    kid: UUID.uuid4(),
    active: true
  })
end

# create lti_1p3 platform roles
if !Claper.Repo.get_by(Lti13.DataProviders.EctoProvider.PlatformRole, id: 1) do
  Lti13.Tool.PlatformRoles.list_roles()
  |> Enum.map(fn t ->
    struct(Lti13.DataProviders.EctoProvider.PlatformRole, Map.from_struct(t))
  end)
  |> Enum.map(&Lti13.DataProviders.EctoProvider.PlatformRole.changeset/1)
  |> Enum.map(fn t -> Claper.Repo.insert!(t, on_conflict: :replace_all, conflict_target: :id) end)
end

# create lti_1p3 context roles
if !Claper.Repo.get_by(Lti13.DataProviders.EctoProvider.ContextRole, id: 1) do
  Lti13.Tool.ContextRoles.list_roles()
  |> Enum.map(fn t ->
    struct(Lti13.DataProviders.EctoProvider.ContextRole, Map.from_struct(t))
  end)
  |> Enum.map(&Lti13.DataProviders.EctoProvider.ContextRole.changeset/1)
  |> Enum.map(fn t -> Claper.Repo.insert!(t, on_conflict: :replace_all, conflict_target: :id) end)
end
