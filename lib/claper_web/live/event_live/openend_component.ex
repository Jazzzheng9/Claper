defmodule ClaperWeb.EventLive.OpenendComponent do
  use ClaperWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        id="collapsed-openend"
        class="bg-black py-3 px-6 text-black shadow-lg mx-auto rounded-full w-max hidden"
      >
        <div class="block w-full h-full cursor-pointer" phx-click={toggle_openend()} phx-target={@myself}>
          <div class="text-white flex space-x-2 items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              fill="none"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
              <path d="M12 3a3 3 0 0 0 -3 3v12a3 3 0 0 0 3 3"></path>
              <path d="M6 3a3 3 0 0 1 3 3v12a3 3 0 0 1 -3 3"></path>
              <path d="M13 7h7a1 1 0 0 1 1 1v8a1 1 0 0 1 -1 1h-7"></path>
              <path d="M5 7h-1a1 1 0 0 0 -1 1v8a1 1 0 0 0 1 1h1"></path>
              <path d="M17 12h.01"></path>
              <path d="M13 12h.01"></path>
            </svg>
            <span class="font-bold"><%= gettext("See Open-ended Question") %></span>
          </div>
        </div>
      </div>
      <div id="extended-openend" style="background-color: rgba(0, 0, 0, 0.7);" class="bg-black w-full py-3 px-6 text-black shadow-lg rounded-md">
        <div class="block w-full h-full cursor-pointer" phx-click={toggle_openend()} phx-target={@myself}>
          <div id="openend-pane" class="float-right mt-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>

          <p class="text-xs text-gray-500 my-1"><%= gettext("Open-ended Question:") %></p>
          <p class="text-white text-lg font-semibold mb-4"><%= @openend.title %></p>
        </div>

      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"openend_submit" => openend_submit_params}, socket) do
    changeset =
      (socket.assigns.current_openend_submit || %Claper.Openends.OpenendSubmit{})
      |> Claper.Openends.change_openend_submit(openend_submit_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "submit",
        %{"openend_submit" => params},
        %{assigns: %{attendee_identifier: attendee_identifier}} = socket
      ) do
    case Claper.Openends.create_or_update_openend_submit(
           socket.assigns.event.uuid,
           %{"response" => params}
           |> Map.put("attendee_identifier", attendee_identifier)
           |> Map.put("openend_id", socket.assigns.openend.id)
         ) do
      {:ok, openend_submit} ->
        event_id = socket.assigns.event.uuid
        list_openend = Claper.Openends.list_openends(event_id)

        # Append the new form_submit to the list of existing form_submits
        {:noreply,
          socket
          |> assign(:current_openend_submit, openend_submit)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end


  @impl true
  def handle_event(
        "submit",
        %{"openend_submit" => params},
        %{assigns: %{current_user: current_user}} = socket
      )
      when is_map(current_user) do
    case Claper.Openends.create_or_update_openend_submit(
           socket.assigns.event.uuid,
           %{"response" => params}
           |> Map.put("user_id", socket.assigns.current_user.id)
           |> Map.put("openend_id", socket.assigns.openend.id)
         ) do
      {:ok, openend_submit} ->
        event_id = socket.assigns.event.uuid
        list_openend = Claper.Openends.list_openends(event_id)

        # Append the new form_submit to the list of existing form_submits
        {:noreply,
          socket
          |> assign(:current_openend_submit, openend_submit)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end


  def toggle_openend(js \\ %JS{}) do
    js
    |> JS.toggle(
      out: "animate__animated animate__zoomOut",
      in: "animate__animated animate__zoomIn",
      to: "#collapsed-openend",
      time: 50
    )
    |> JS.toggle(
      out: "animate__animated animate__zoomOut",
      in: "animate__animated animate__zoomIn",
      to: "#extended-openend"
    )
  end
end

# the version of last unsuccessful test.
