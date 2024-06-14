defmodule Lti13.PlatformInstances do
  import Ecto.Query, warn: false
  alias Claper.Repo
  alias Lti13.PlatformInstances.PlatformInstance

  def create_platform_instance(attrs) do
    %PlatformInstance{}
    |> PlatformInstance.changeset(attrs)
    |> Repo.insert()
  end

  def get_platform_instance_by_client_id(client_id),
    do: Repo.get_by(PlatformInstance, client_id: client_id)
end
