defmodule Claper.Openends do
  @moduledoc """
  The Forms context.
  """

  import Ecto.Query, warn: false
  alias Claper.Repo

  alias Claper.Openends.Openend
  alias Claper.Openends.OpenendSubmit
  alias Claper.Openends.Field

  @doc """
  Returns the list of forms for a given presentation file.

  ## Examples

      iex> list_forms(123)
      [%Form{}, ...]

  """
  def list_openends(presentation_file_id) do
    from(o in Openend,
      where: o.presentation_file_id == ^presentation_file_id,
      order_by: [asc: o.id, asc: o.position]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of forms for a given presentation file and a given position.

  ## Examples

      iex> list_forms_at_position(123, 0)
      [%Form{}, ...]

  """
  def list_openends_at_position(presentation_file_id, position) do
    from(o in Openend,
      where: o.presentation_file_id == ^presentation_file_id and o.position == ^position,
      order_by: [asc: o.id]
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
  def get_openend!(id, preload \\ []),
    do: Repo.get!(Openend, id) |> Repo.preload(preload)

  @doc """
  Gets a single form for a given position.

  ## Examples

      iex> get_form!(123, 0)
      %Form{}

  """
  def get_openend_current_position(presentation_file_id, position) do
    from(o in Openend,
      where:
        o.position == ^position and o.presentation_file_id == ^presentation_file_id and
          o.enabled == true
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
  def create_openend(attrs \\ %{}) do
    %Openend{}
    |> Openend.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, openend} ->
        openend = Repo.preload(openend, presentation_file: :event)
        broadcast({:ok, openend, openend.presentation_file.event.uuid}, :openend_created)

      {:error, changeset} ->
        {:error, %{changeset | action: :insert}}
    end
  end

  @doc """
  Updates a form.

  ## Examples

      iex> update_form("123e4567-e89b-12d3-a456-426614174000", form, %{field: new_value})
      {:ok, %Form{}}

      iex> update_form("123e4567-e89b-12d3-a456-426614174000", form, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_openend(event_uuid, %Openend{} = openend, attrs) do
    openend
    |> Openend.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, openend} ->
        broadcast({:ok, openend, event_uuid}, :openend_updated)

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
  def delete_openend(event_uuid, %Openend{} = openend) do
    {:ok, openend} = Repo.delete(openend)
    broadcast({:ok, openend, event_uuid}, :openend_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking form changes.

  ## Examples

      iex> change_form(form)
      %Ecto.Changeset{data: %Form{}}

  """
  def change_openend(%Openend{} = openend, attrs \\ %{}) do
    Openend.changeset(openend, attrs)
  end

  @doc """
  Add an empty form field to a form changeset.
  """
  def add_openend_field(changeset) do
    changeset
    |> Ecto.Changeset.put_embed(
      :fields,
      Ecto.Changeset.get_field(changeset, :fields) ++ [%Field{}]
    )
  end

  @doc """
  Remove a form field from a form changeset.
  """
  def remove_openend_field(changeset, field) do
    changeset
    |> Ecto.Changeset.put_embed(
      :fields,
      Ecto.Changeset.get_field(changeset, :fields) -- [field]
    )
  end

  def disable_all(presentation_file_id, position) do
    from(o in Openend,
      where: o.presentation_file_id == ^presentation_file_id and o.position == ^position
    )
    |> Repo.update_all(set: [enabled: false])
  end

  def set_enabled(id) do
    get_openend!(id)
    |> Ecto.Changeset.change(enabled: true)
    |> Repo.update()
  end

  def set_disabled(id) do
    get_openend!(id)
    |> Ecto.Changeset.change(enabled: false)
    |> Repo.update()
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
  Creates a form submit.

  ## Examples

      iex> create_form_submit(%{field: value})
      {:ok, %FormSubmit{}}

      iex> create_form_submit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_openend_submit(attrs \\ %{}) do
    %OpenendSubmit{}
    |> OpenendSubmit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of form submissions for a given presentation file.

  ## Examples

      iex> list_form_submits(123)
      [%FormSubmit{}, ...]

  """
  def list_openend_submits(presentation_file_id, preload \\ []) do
    from(os in OpenendSubmit,
      join: o in Openend,
      on: o.id == os.openend_id,
      where: o.presentation_file_id == ^presentation_file_id
    )
    |> Repo.all()
    |> Repo.preload(preload)
  end

  @doc """
  Gets a single FormSubmit.

  ## Examples

      iex> get_form_submit!(321, 123)
      %FormSubmit{}

  """
  def get_openend_submit(user_id, openend_id) when is_number(user_id),
    do: Repo.get_by(OpenendSubmit, openend_id: openend_id, user_id: user_id)

  def get_openend_submit(attendee_identifier, openend_id),
    do: Repo.get_by(OpenendSubmit, openend_id: openend_id, attendee_identifier: attendee_identifier)

  @doc """
  Gets a single FormSubmit by its ID.

  Raises `Ecto.NoResultsError` if the FormSubmit does not exist.

  ## Examples

      iex> get_form_submit_by_id!("123e4567-e89b-12d3-a456-426614174000")
      %Post{}

      iex> get_form_submit_by_id!("123e4567-e89b-12d3-a456-426614174123")
      ** (Ecto.NoResultsError)

  """
  def get_openend_submit_by_id!(id, preload \\ []),
    do: Repo.get_by!(OpenendSubmit, id: id) |> Repo.preload(preload)

  @doc """
  Creates or update a FormSubmit.

  ## Examples

      iex> create_or_update_form_submit(%{field: value})
      {:ok, %FormSubmit{}}

      iex> create_or_update_form_submit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_openend_submit(
        event_uuid,
        %{"user_id" => user_id, "openend_id" => openend_id} = attrs
      )
      when is_number(user_id) do
    get_openend_submit(user_id, openend_id) |> create_or_update_openend_submit(event_uuid, attrs)
  end

  def create_or_update_openend_submit(
        event_uuid,
        %{"attendee_identifier" => attendee_identifier, "openend_id" => openend_id} = attrs
      ) do
    get_openend_submit(attendee_identifier, openend_id)
    |> create_or_update_openend_submit(event_uuid, attrs)
  end

  def create_or_update_openend_submit(os, event_uuid, attrs) do
    case os do
      nil -> %OpenendSubmit{}
      openend_submit -> openend_submit
    end
    |> OpenendSubmit.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, r} ->
        # Preloading form in FormSubmit
        r = Repo.preload(r, :openend)

        case os do
          nil -> broadcast({:ok, r, event_uuid}, :openend_submit_created)
          _openend_submit -> broadcast({:ok, r, event_uuid}, :openend_submit_updated)
        end
    end
  end

  @doc """
  Deletes a form submit.

  ## Examples

      iex> delete_form_submit(post, event_id)
      {:ok, %FormSubmit{}}

      iex> delete_form_submit(post, event_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_openend_submit(event_uuid, %OpenendSubmit{} = os) do
    os
    |> Repo.delete()
    |> case do
      {:ok, r} -> broadcast({:ok, r, event_uuid}, :openend_submit_deleted)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking form submit changes.

  ## Examples

      iex> change_form_submit(form_submit)
      %Ecto.Changeset{data: %FormSubmit{}}

  """
  def change_openend_submit(%OpenendSubmit{} = openend_submit, attrs \\ %{}) do
    OpenendSubmit.changeset(openend_submit, attrs)
  end




end
