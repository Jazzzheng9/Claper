defmodule Lti13.Users do
  import Ecto.Query, warn: false
  alias Claper.Repo

  alias Lti13.Users.User

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_sub(sub) do
    Repo.get_by(User, sub: sub)
  end

  def get_or_create_user(%{sub: sub, email: email} = attrs) do
    case get_user_by_sub(sub) do
      nil ->
        case Claper.Accounts.get_user_by_email_or_create(email) do
          {:ok, claper_user} ->
            updated_attrs = Map.put(attrs, :user_id, claper_user.id)

            case create_user(updated_attrs) do
              {:ok, user} ->
                user

              {:error, _} ->
                {:error, %{reason: :invalid_user, msg: "Invalid user"}}
            end

          {:error, _} ->
            {:error, %{reason: :invalid_user, msg: "Invalid Claper user"}}
        end

      %User{} = user ->
        user
    end
  end
end
