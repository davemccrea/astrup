defmodule AstrupWeb.ECGViewerLive do
  use AstrupWeb, :live_view

  alias Astrup.ECG
  alias Astrup.ECG.DatasetRegistry

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:env, Application.get_env(:astrup, :env))
      |> assign(:ecg_saved, false)
      |> assign(:metadata, %{})
      |> assign(:ecg_data, nil)

    {:ok, socket}
  end

  def handle_params(%{"dataset_name" => dataset_name, "filename" => filename}, _uri, socket)
      when not is_nil(dataset_name) and not is_nil(filename) do
    ecg_data = Astrup.Wfdb.read(dataset_name, filename)
    qrs = Astrup.Wfdb.detect_qrs(dataset_name, filename)
    ecg_saved = ECG.is_ecg_saved?(socket.assigns.current_scope, dataset_name, filename)
    metadata = load_dataset_metadata(dataset_name, filename)

    {:noreply,
     socket
     |> assign(:ecg_data, Map.put(ecg_data, :qrs, qrs))
     |> assign(:dataset_name, dataset_name)
     |> assign(:filename, filename)
     |> assign(:ecg_saved, ecg_saved)
     |> assign(:metadata, metadata)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} locale={@locale} current_scope={@current_scope}>
      <%= if @ecg_data do %>
        <div class="space-y-8">
          <div class="flex justify-between items-center">
            <h1 class="text-2xl font-bold">{gettext("ECG Viewer")}</h1>
          </div>

          <.live_component
            module={AstrupWeb.Components.EcgPlayer}
            id="ecg-player"
            env={@env}
            ecg_data={@ecg_data}
            current_scope={@current_scope}
          >
            <:actions>
              <.button
                phx-click={if @ecg_saved, do: "unsave_ecg", else: "save_ecg"}
                class="btn btn-square"
                id="save-ecg-button"
              >
                <span :if={@ecg_saved}>
                  Unsave <.icon class="h-5 w-5" name="hero-trash" />
                </span>

                <span :if={!@ecg_saved}>
                  Save <.icon class="h-5 w-5" name="hero-document-arrow-down" />
                </span>
              </.button>
            </:actions>

            <:sidebar>
              <AstrupWeb.Components.ClinicalInfoPanel.clinical_info_panel metadata={@metadata} />
            </:sidebar>

            <:instructions>
              <AstrupWeb.Components.EcgInstructions.default_instructions />
            </:instructions>
          </.live_component>
        </div>
      <% else %>
        <div class="text-center space-y-2">
          <.icon name="hero-heart" class="opacity-30 w-16 h-16 mx-auto" />
          <p class="text-lg font-medium">No ECG Data Loaded</p>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  def handle_event("save_ecg", _params, socket) do
    case ECG.save_ecg(socket.assigns.current_scope, %{
           db_name: socket.assigns.dataset_name,
           filename: socket.assigns.filename
         }) do
      {:ok, _saved_ecg} ->
        socket = assign(socket, :ecg_saved, true)
        {:noreply, put_flash(socket, :info, "ECG saved successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save ECG")}
    end
  end

  def handle_event("unsave_ecg", _params, socket) do
    {count, _} =
      ECG.unsave_ecg(
        socket.assigns.current_scope,
        socket.assigns.dataset_name,
        socket.assigns.filename
      )

    if count > 0 do
      socket = assign(socket, :ecg_saved, false)
      {:noreply, put_flash(socket, :info, "ECG unsaved successfully!")}
    else
      {:noreply, put_flash(socket, :error, "Failed to unsave ECG")}
    end
  end

  def handle_event("load_random_ecg", _params, socket) do
    # TODO
    {:noreply, socket}
  end

  defp load_dataset_metadata(dataset_name, filename) do
    with dataset_module when not is_nil(dataset_module) <-
           DatasetRegistry.get_dataset(dataset_name),
         record when not is_nil(record) <- dataset_module.get_by_filename(filename) do
      dataset_module.get_metadata(record)
    else
      _ -> %{}
    end
    |> dbg()
  end
end
