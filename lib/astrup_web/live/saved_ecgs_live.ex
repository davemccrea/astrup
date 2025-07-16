defmodule AstrupWeb.SavedEcgsLive do
  use AstrupWeb, :live_view

  alias Astrup.ECG
  alias Astrup.ECG.DatasetRegistry

  def mount(_params, _session, socket) do
    saved_ecgs = ECG.get_users_saved_ecgs(socket.assigns.current_scope)

    enriched_ecgs = enrich_ecgs_with_metadata(saved_ecgs)

    {:ok, socket |> assign(saved_ecgs: enriched_ecgs)}
  end

  defp enrich_ecgs_with_metadata(saved_ecgs) do
    Enum.map(saved_ecgs, fn ecg ->
      metadata = get_ecg_metadata(ecg.db_name, ecg.filename)
      Map.put(ecg, :metadata, metadata)
    end)
  end

  defp get_ecg_metadata(dataset_name, filename) do
    case DatasetRegistry.get_dataset(dataset_name) do
      nil ->
        nil

      dataset_module ->
        case dataset_module.get_by_filename(filename) do
          nil ->
            nil

          record ->
            query_module = Module.concat(dataset_module, Query)
            query_module.get_metadata(record)
        end
    end
  end

  def handle_event("remove_ecg", %{"id" => id}, socket) do
    id = String.to_integer(id)

    case ECG.delete_saved_ecg(socket.assigns.current_scope, id) do
      {count, _} when count > 0 ->
        saved_ecgs = ECG.get_users_saved_ecgs(socket.assigns.current_scope)
        enriched_ecgs = enrich_ecgs_with_metadata(saved_ecgs)

        {:noreply,
         socket
         |> assign(saved_ecgs: enriched_ecgs)
         |> put_flash(:info, "ECG removed successfully")}

      _ ->
        {:noreply, socket |> put_flash(:error, "Failed to remove ECG")}
    end
  end

  defp get_rhythm(nil), do: "N/A"

  defp get_rhythm(metadata) do
    case metadata.scp_codes do
      nil ->
        "N/A"

      scp_codes ->
        rhythm_code =
          scp_codes
          |> Enum.find(&(&1.kind == :rhythm))

        case rhythm_code do
          nil -> "N/A"
          %{description: description} -> description
        end
    end
  end

  defp get_primary_diagnosis(nil), do: "N/A"

  defp get_primary_diagnosis(metadata) do
    case metadata.scp_codes do
      nil ->
        "N/A"

      scp_codes ->
        diagnostic_code =
          scp_codes
          |> Enum.filter(&(&1.kind == :diagnostic))
          |> Enum.max_by(& &1.confidence, fn -> nil end)

        case diagnostic_code do
          nil -> "N/A"
          %{description: description} when description != nil -> description
          _ -> "OTHER"
        end
    end
  end

  defp get_full_report(nil), do: "N/A"

  defp get_full_report(metadata) do
    case metadata.report do
      nil -> "N/A"
      "" -> "N/A"
      report -> report
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} locale={@locale} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-bold mb-6">Saved ECGs</h1>
        <div class="overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>Rhythm</th>
                <th>Primary Diagnosis</th>
                <th>Date Saved</th>
                <th>Record ID</th>
                <th>Report</th>
                <th>Avg Pulse</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={ecg <- @saved_ecgs} class="hover:bg-base-200">
                <td class="text-sm max-w-24 truncate" title={get_rhythm(ecg.metadata)}>
                  {get_rhythm(ecg.metadata)}
                </td>
                <td class="text-sm max-w-32 truncate" title={get_primary_diagnosis(ecg.metadata)}>
                  {get_primary_diagnosis(ecg.metadata)}
                </td>
                <td
                  class="text-sm max-w-20 truncate"
                  title={Calendar.strftime(ecg.inserted_at, "%d.%m.%Y")}
                >
                  {Calendar.strftime(ecg.inserted_at, "%d.%m.%Y")}
                </td>
                <td
                  class="font-mono text-xs max-w-32 truncate"
                  title={"#{ecg.db_name}/#{ecg.filename}"}
                >
                  {ecg.db_name}/{ecg.filename}
                </td>
                <td class="text-sm max-w-40 truncate" title={get_full_report(ecg.metadata)}>
                  {get_full_report(ecg.metadata)}
                </td>
                <td class="text-sm text-gray-500 max-w-16 truncate" title="TBD">TBD</td>
                <td>
                  <div class="flex gap-2">
                    <.link
                      href={~p"/ecg/viewer?dataset_name=#{ecg.db_name}&filename=#{ecg.filename}"}
                      class="btn btn-sm btn-primary"
                      title="View ECG"
                    >
                      <.icon name="hero-eye" class="w-4 h-4" />
                    </.link>
                    <button
                      phx-click="remove_ecg"
                      phx-value-id={ecg.id}
                      class="btn btn-sm btn-error"
                      data-confirm="Are you sure you want to remove this saved ECG?"
                      title="Remove ECG"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
