defmodule AstrupWeb.Components.EcgPlayer do
  alias Astrup.Repo
  alias Astrup.Settings
  use AstrupWeb, :live_component

  def update(assigns, socket) do
    # Load settings within component based on current scope
    settings = Settings.get_settings(assigns.current_scope)

    form =
      settings
      |> Settings.changeset(%{})
      |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(settings: settings)
     |> assign(form: form)
     |> assign(
       :lead_names,
       if(assigns.ecg_data, do: Map.get(assigns.ecg_data, "sig_name", []), else: [])
     )
     |> push_event("load_ecg_data", %{data: assigns.ecg_data})}
  end

  attr :env, :string, required: true, doc: "Application environment"
  attr :ecg_data, :map, default: nil, doc: "ECG data to be pushed to the hook"
  attr :current_scope, :any, required: true, doc: "Current scope for loading settings"

  slot :actions, doc: "Action buttons displayed in the header"
  slot :sidebar, doc: "Content displayed in the sidebar panel"
  slot :instructions, doc: "Help text displayed when ECG is loaded"

  def render(assigns) do
    ~H"""
    <div class="space-y-12 w-full">
      <div class="space-y-4 w-full">
        <%= if @actions != [] do %>
          <div class="flex justify-end gap-4">
            {render_slot(@actions)}
          </div>
        <% end %>

        <div class="relative py-8">
          <div id="ecg-player" phx-hook="ECGPlayer" phx-update="ignore" phx-target={@myself}>
            <div data-ecg-chart></div>
          </div>

          <div class="flex justify-between mt-2">
            <.button id="play-pause-button" class="btn btn-sm">
              <.icon name="hero-play" class="w-4 h-4" />
              <span class="ml-1">Play</span>
            </.button>

            <%= if @instructions != [] do %>
              {render_slot(@instructions)}
            <% else %>
              <AstrupWeb.Components.EcgInstructions.default_instructions />
            <% end %>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {render_slot(@sidebar)}

        <.form for={@form} phx-change="settings_updated" phx-target={@myself}>
          <div class="space-y-6">
            <div class="card bg-base-200 shadow">
              <div class="card-body">
                <h2 class="card-title">
                  <.icon name="hero-adjustments-horizontal" class="w-5 h-5" /> ECG Controls
                </h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <.input
                      type="select"
                      id="display-mode-selector"
                      label="Display Mode"
                      field={@form[:display_mode]}
                      options={[{"Single Lead", "single"}, {"All Leads", "multi"}]}
                    />
                  </div>

                  <div id="lead-selector-container">
                    <.input
                      type="select"
                      id="lead-selector"
                      label="Current Lead"
                      field={@form[:current_lead]}
                      options={
                        for {name, index} <- Enum.with_index(@lead_names) do
                          {"Lead #{name}", "#{index}"}
                        end
                      }
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="card bg-base-200 shadow">
              <div class="card-body">
                <h2 class="card-title">
                  <.icon name="hero-cog-6-tooth" class="w-5 h-5" /> View Options
                </h2>
                <div class="space-y-6">
                  <div>
                    <.input
                      type="select"
                      id="grid-type-selector"
                      label="Grid Type"
                      field={@form[:grid_type]}
                      options={[{"Graph Paper", "graph_paper"}, {"Telemetry", "telemetry"}]}
                    />
                  </div>

                  <div class="space-y-4 w-1/2">
                    <h3 class="text-sm font-medium text-base-content/70">Scale Adjustments</h3>

                    <div class="space-y-3">
                      <div class="flex flex-col space-y-2">
                        <div class="flex justify-between items-center">
                          <span class="text-sm font-medium">Grid Scale</span>
                          <div class="flex items-center gap-2">
                            <span id="grid-scale-value" class="text-xs text-base-content/70">
                              {Phoenix.HTML.Form.input_value(@form, :grid_scale) || "1.00"}x
                            </span>
                            <span id="grid-scale-speed" class="text-xs text-base-content/50">
                              25.0 mm/s
                            </span>
                          </div>
                        </div>
                        <.input
                          type="range"
                          id="grid-scale-slider"
                          field={@form[:grid_scale]}
                          min="0.75"
                          max="1.25"
                          step="0.01"
                          class="range range-xs w-full"
                        />
                      </div>

                      <div class="flex flex-col space-y-2">
                        <div class="flex justify-between items-center">
                          <span class="text-sm font-medium">Amplitude Scale</span>
                          <div class="flex items-center gap-2">
                            <span id="amplitude-scale-value" class="text-xs text-base-content/70">
                              {Phoenix.HTML.Form.input_value(@form, :amplitude_scale) || "1.00"}x
                            </span>
                            <span id="amplitude-scale-gain" class="text-xs text-base-content/50">
                              10.0 mm/mV
                            </span>
                          </div>
                        </div>
                        <.input
                          type="range"
                          id="amplitude-scale-slider"
                          field={@form[:amplitude_scale]}
                          min="0.75"
                          max="1.25"
                          step="0.01"
                          class="range range-xs w-full"
                        />
                      </div>

                      <div class="flex flex-col space-y-2">
                        <div class="flex justify-between items-center">
                          <span class="text-sm font-medium">Height Scale</span>
                          <div class="flex items-center gap-2">
                            <span id="height-scale-value" class="text-xs text-base-content/70">
                              {Phoenix.HTML.Form.input_value(@form, :height_scale) || "1.20"}x
                            </span>
                            <span id="height-scale-pixels" class="text-xs text-base-content/50">
                              180px
                            </span>
                          </div>
                        </div>
                        <.input
                          type="range"
                          id="height-scale-slider"
                          field={@form[:height_scale]}
                          min="0.95"
                          max="1.45"
                          step="0.01"
                          class="range range-xs w-full"
                        />
                      </div>
                    </div>
                  </div>

                  <div class="space-y-3">
                    <h3 class="text-sm font-medium text-base-content/70">Playback Options</h3>

                    <div class="space-y-2">
                      <.input
                        type="checkbox"
                        id="loop-checkbox"
                        label="Loop playback"
                        field={@form[:loop_playback]}
                      />

                      <.input
                        type="checkbox"
                        id="qrs-indicator-checkbox"
                        label="QRS pulse indicator"
                        field={@form[:qrs_indicator]}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("settings_updated", %{"settings" => params}, socket) do
    socket.assigns.settings
    |> Settings.changeset(params)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        with {:ok, updated_settings} <- Repo.update(changeset) do
          form = updated_settings |> Settings.changeset(%{}) |> to_form()

          {:noreply,
           socket
           |> assign(settings: updated_settings)
           |> assign(form: form)}
        end

      changeset ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
