defmodule Claper.Forms do
  @moduledoc """
  The Forms context.
  """

  import Ecto.Query, warn: false
  alias Claper.Repo

  alias Claper.Forms.Form
  alias Claper.Forms.FormSubmit

  @doc """
  Returns the list of forms for a given presentation file.

  ## Examples

      iex> list_forms(123)
      [%Form{}, ...]

  """
  def list_forms(presentation_file_id) do
    from(f in Form,
      where: f.presentation_file_id == ^presentation_file_id,
      order_by: [asc: f.id, asc: f.position]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of forms for a given presentation file and a given position.

  ## Examples

      iex> list_forms_at_position(123, 0)
      [%Form{}, ...]

  """
  def list_forms_at_position(presentation_file_id, position) do
    from(f in Form,
      where: f.presentation_file_id == ^presentation_file_id and f.position == ^position,
      order_by: [asc: f.id]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single form.

  Raises `Ecto.NoResultsError` if the Form does not exist.

  ## Examples

      iex> get_form!(123)
      %Poll{}

      iex> get_form!(456)
      ** (Ecto.NoResultsError)

  """
  def get_form!(id),
    do:
      Repo.get!(Form, id)

  @doc """
  Gets a single form for a given position.

  ## Examples

      iex> get_form!(123, 0)
      %Form{}

  """
  def get_form_current_position(presentation_file_id, position) do
    from(f in Form,
      where:
        f.position == ^position and f.presentation_file_id == ^presentation_file_id and
          f.enabled == true
    )
    |> Repo.one()
  end

  @doc """
  Creates a form.

  ## Examples

      iex> create_form(%{field: value})
      {:ok, %Form{}}

      iex> create_form(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_form(attrs \\ %{}) do
    %Form{}
    |> Form.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a form.

  ## Examples

      iex> update_form("123e4567-e89b-12d3-a456-426614174000", form, %{field: new_value})
      {:ok, %Form{}}

      iex> update_form("123e4567-e89b-12d3-a456-426614174000", form, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_form(event_uuid, %Form{} = form, attrs) do
    form
    |> Form.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, form} ->
        broadcast({:ok, form, event_uuid}, :form_updated)

      {:error, changeset} ->
        {:error, %{changeset | action: :update}}
    end
  end

  @doc """
  Deletes a form.

  ## Examples

      iex> delete_form("123e4567-e89b-12d3-a456-426614174000", form)
      {:ok, %Form{}}

      iex> delete_form("123e4567-e89b-12d3-a456-426614174000", form)
      {:error, %Ecto.Changeset{}}

  """
  def delete_form(event_uuid, %Form{} = form) do
    {:ok, form} = Repo.delete(form)
    broadcast({:ok, form, event_uuid}, :form_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking form changes.

  ## Examples

      iex> change_form(form)
      %Ecto.Changeset{data: %Form{}}

  """
  def change_form(%Form{} = form, attrs \\ %{}) do
    Form.changeset(form, attrs)
  end

  def disable_all(presentation_file_id, position) do
    from(f in Form,
      where:
        f.presentation_file_id == ^presentation_file_id and f.position == ^position
    )
    |> Repo.update_all(set: [enabled: false])
  end

  def set_default(id, presentation_file_id, position) do
    from(f in Form,
      where:
        f.presentation_file_id == ^presentation_file_id and f.position == ^position and
          f.id != ^id
    )
    |> Repo.update_all(set: [enabled: false])

    from(f in Form,
      where:
        f.presentation_file_id == ^presentation_file_id and f.position == ^position and
          f.id == ^id
    )
    |> Repo.update_all(set: [enabled: true])
  end

  defp broadcast({:error, _reason} = error, _form), do: error

  defp broadcast({:ok, form, event_uuid}, event) do
    Phoenix.PubSub.broadcast(
      Claper.PubSub,
      "event:#{event_uuid}",
      {event, form}
    )

    {:ok, form}
  end

  @doc """
  Gets a single form_submit.

  ## Examples

      iex> get_form_submit!(321, 123)
      %PollVote{}

  """
  def get_form_submit(user_id, form_id) when is_number(user_id),
    do: Repo.get_by(FormSubmit, form_id: form_id, user_id: user_id)

  def get_form_submit(attendee_identifier, form_id),
    do: Repo.get_by(FormSubmit, form_id: form_id, attendee_identifier: attendee_identifier)

  @doc """
  Creates a FormSubmit.

  ## Examples

      iex> create_form_submit(%{field: value})
      {:ok, %PollVote{}}

      iex> create_form_submit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_form_submit(attrs \\ %{}) do
    %FormSubmit{}
    |> FormSubmit.changeset(attrs)
    |> Repo.insert()
  end
end
