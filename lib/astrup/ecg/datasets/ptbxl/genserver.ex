defmodule Astrup.ECG.Datasets.Ptbxl.GenServer do
  use GenServer

  alias Astrup.ECG.Datasets.Ptbxl.{Parser, Query}

  @impl true
  def init(_opts) do
    ecg_databases_path = Application.get_env(:astrup, :ecg_databases_path)
    csv_file = Path.join(ecg_databases_path, "/ptbxl/ptbxl_database.csv")

    case Parser.parse_file(csv_file) do
      {:ok, data} ->
        filtered_records =
          data.rows
          |> Query.filter_signal_quality()
          |> Query.filter_high_quality()
          |> Query.filter_human_validated()
          |> Query.filter_confidence_100()

        {:ok, %{records: filtered_records, csv_file: csv_file}}

      {:error, reason} ->
        {:stop, {:error, "Failed to load PTB-XL data: #{reason}"}}
    end
  end

  @impl true
  def handle_call(:get_all_records, _from, state), do: {:reply, state.records, state}

  @impl true
  def handle_call({:get_by_filename, filename}, _from, state) do
    record = Enum.find(state.records, fn record -> record.filename_lr == filename end)

    {:reply, record, state}
  end

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
end
