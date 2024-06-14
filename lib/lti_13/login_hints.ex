defmodule Lti13.LoginHints do
  import Ecto.Query, warn: false
  alias Claper.Repo
  alias Lti13.LoginHints.LoginHint

  def get_login_hint_by_value(value),
    do: Repo.get_by(LoginHint, value: value)

  def create_login_hint(attrs) do
    %LoginHint{}
    |> LoginHint.changeset(attrs)
    |> Repo.insert()
  end

  def delete_expired_login_hints(login_hint_ttl_sec \\ 86_400) do
    login_hint_expiry =
      DateTime.utc_now() |> DateTime.add(-login_hint_ttl_sec, :second)

    Repo.delete_all(from(h in LoginHint, where: h.inserted_at < ^login_hint_expiry))
  end
end
