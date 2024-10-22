defmodule ClaperWeb.OpenendLive.FormComponent do
  use ClaperWeb, :live_component

  alias Claper.Openends

  @impl true
  def update(%{openend: openend} = assigns, socket) do
    changeset = Openends.change_openend(openend)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:dark, fn -> false end)
     |> assign(:openends, list_openends(assigns))
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    openend = Openends.get_openend!(id)
    {:ok, _} = Openends.delete_openend(socket.assigns.event_uuid, openend)

    {:noreply, socket |> push_navigate(to: socket.assigns.return_to)}
  end

  @impl true
  def handle_event("validate", %{"openend" => openend_params}, socket) do
    changeset =
      socket.assigns.openend
      |> Openends.change_openend(openend_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"openend" => openend_params}, socket) do
    save_openend(socket, socket.assigns.live_action, openend_params)
  end

  @impl true
  def handle_event("add_field", _params, %{assigns: %{changeset: changeset}} = socket) do
    {:noreply, assign(socket, :changeset, changeset |> Openends.add_openend_field())}
  end

  @impl true
  def handle_event(
        "remove_field",
        %{"field" => field} = _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {field, _} = Integer.parse(field)

    openend_field = Enum.at(Ecto.Changeset.get_field(changeset, :fields), field)

    {:noreply, assign(socket, :changeset, changeset |> Openends.remove_openend_field(openend_field))}
  end

  defp save_openend(socket, :edit, openend_params) do
    case Openends.update_openend(
           socket.assigns.event_uuid,
           socket.assigns.openend,
           openend_params
         ) do
      {:ok, _openend} ->
        {:noreply,
         socket
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_openend(socket, :new, openend_params) do
    case Openends.create_openend(
           openend_params
           |> Map.put("presentation_file_id", socket.assigns.presentation_file.id)
           |> Map.put("position", socket.assigns.position)
           |> Map.put("enabled", false)
         ) do
      {:ok, openend} ->
        {:noreply,
         socket
         |> maybe_change_current_openend(openend)
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp maybe_change_current_openend(socket, %{enabled: true} = openend) do
    openend = Openends.get_openend!(openend.id)

    Phoenix.PubSub.broadcast(
      Claper.PubSub,
      "event:#{socket.assigns.event_uuid}",
      {:current_openend, openend}
    )

    socket
  end

  defp maybe_change_current_openend(socket, _), do: socket

  defp list_openends(assigns) do
    Openends.list_openends(assigns.presentation_file.id)
  end
end
