defmodule AstrupWeb.ReferenceValues.QuizLive do
  @moduledoc """
  Blood gas quiz for testing knowledge of reference values.

  The application can be in one of the following states:
  - `:ready`: Initial state when the page loads.
  - `:answering`: When the user is making selections.
  - `:review`: After the user clicks "Check Answers" and the answers are evaluated.
  """
  use AstrupWeb, :live_view
  alias Astrup.PatientCase

  @type state :: :ready | :answering | :review

  defp setup(socket, session) do
    current_lab = session["current_lab"] || "Astrup.Lab.Fimlab"
    lab_module = Module.concat([current_lab])
    current_analyzer = session["current_analyzer"] || "Astrup.Analyzer.RadiometerAbl90FlexPlus"
    analyzer = Module.concat([current_analyzer])
    selections = analyzer.blank_parameter_quiz_selections()

    sample_number = Enum.random(10000..99999)

    random_minutes = Enum.random(-60..-2)

    sample_date =
      "Europe/Helsinki"
      |> DateTime.now!()
      |> DateTime.add(random_minutes, :minute)

    printed_date =
      "Europe/Helsinki"
      |> DateTime.now!()
      |> DateTime.add(random_minutes, :minute)
      |> DateTime.add(2, :minute)

    socket
    |> assign(sample_number: sample_number)
    |> assign(sample_date: sample_date)
    |> assign(printed_date: printed_date)
    |> assign(:state, :ready)
    |> assign(:selections, selections)
    |> assign(:number_of_parameters, map_size(selections))
    |> assign(:printout, PatientCase.get_random_case())
    |> assign(:lab_module, lab_module)
    |> assign(:age_range, "31-50")
    |> assign(:sex, "female")
    |> assign(:analyzer, analyzer)
    |> assign(:hints_enabled, false)
  end

  @impl true
  def mount(_, session, socket) do
    {:ok, setup(socket, session)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} locale={@locale} current_scope={@current_scope}>
      <div class="container mx-auto px-2 sm:px-4 py-4 sm:py-8">
        <div class="mb-8">
          <h1 class="text-2xl sm:text-3xl font-bold mb-4">
            {gettext("ABG Reference Values Quiz")}
          </h1>
          <p class="text-base-content/70 mb-6">
            {gettext("Test your knowledge of ABG parameter reference ranges")}
          </p>
          
    <!-- Navigation back to Learn -->
          <div class="mb-8">
            <.link navigate={~p"/reference-values/learn"} class="btn btn-primary">
              <.icon name="hero-arrow-left" class="w-5 h-5" />
              {gettext("Back to Learning")}
            </.link>
          </div>
        </div>

        <div class="flex flex-col lg:flex-row gap-6 max-w-7xl mx-auto">
          <div class="lg:sticky lg:top-4 lg:self-start space-y-4 w-full lg:w-80 order-1 lg:order-1">
            <%= if @state == :review do %>
              <.score_section score={correct_count(@selections)} total={total_count(@selections)} />
            <% end %>

            <section class="space-y-4 border border-base-content/20 shadow p-4">
              <h1 class="text-lg font-semibold mb-3 text-primary">{gettext("Instructions")}</h1>
              <p class="mb-4">
                {gettext(
                  "For each parameter, select whether the value is Low (L), Normal (N), or High (H) compared to its reference range. Once you\'ve made all 18 selections, click \"Check Answers\"."
                )}
              </p>

              <div class="mb-4 text-base-content/70">
                {gettext("Answers: ")} {number_of_selections_made(@selections)}/18
              </div>

              <div class="flex flex-col gap-3">
                <button
                  id="check-answers"
                  phx-click="check_answers"
                  class="btn btn-primary w-full"
                  disabled={@state == :review}
                >
                  {gettext("Check Answers")}
                </button>
                <button phx-click="next" class="btn btn-secondary w-full" disabled={@state != :review}>
                  {gettext("Next")} <.icon name="hero-arrow-right" />
                </button>
              </div>
            </section>

            <section class="border rounded-none border-base-content/20 shadow p-4">
              <h2 class="text-lg font-semibold mb-3 text-primary">
                {gettext("Settings")}
              </h2>

              <.form for={%{}} class="space-y-3" phx-change="update_settings">
                <div>
                  <.input
                    type="select"
                    name="age_range"
                    label={gettext("Age Range")}
                    value={@age_range}
                    options={[
                      {"0-18", "0-18"},
                      {"18-30", "18-30"},
                      {"31-50", "31-50"},
                      {"51-60", "51-60"},
                      {"61-70", "61-70"},
                      {"71-80", "71-80"},
                      {">80", ">80"}
                    ]}
                  />
                  <p class="text-sm text-base-content/50 -mt-1">
                    {gettext("Note: determines pO2")}
                  </p>
                </div>

                <div>
                  <.input
                    type="select"
                    name="sex"
                    label={gettext("Sex")}
                    value={@sex}
                    options={[
                      {gettext("Male"), "male"},
                      {gettext("Female"), "female"}
                    ]}
                  />
                  <p class="text-sm text-base-content/50 -mt-1">
                    {gettext("Note: determines Hb")}
                  </p>
                </div>

                <.input
                  type="checkbox"
                  name="hints_enabled"
                  label={gettext("Show hover hints")}
                  checked={@hints_enabled}
                />
              </.form>
            </section>
          </div>

          <div class="w-full lg:flex-1 order-2 lg:order-2">
            <AstrupWeb.RadiometerABL90FlexPlus.render
              printout={@printout}
              selections={@selections}
              state={@state}
              hints_enabled={@hints_enabled}
              get_reference_range={
                fn parameter ->
                  Astrup.pretty_print_reference_range(@lab_module, parameter, %{
                    age_range: @age_range,
                    sex: @sex
                  })
                end
              }
              get_unit={fn parameter -> @analyzer.get_unit_by_parameter(parameter) end}
              sample_date={@sample_date}
              printed_date={@printed_date}
              quiz?={true}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("update_settings", params, socket) do
    %{
      "age_range" => age_range,
      "sex" => sex,
      "hints_enabled" => hints_enabled
    } = params

    hints_enabled =
      case hints_enabled do
        "true" -> true
        "false" -> false
        _ -> false
      end

    {:noreply,
     socket
     |> assign(:age_range, age_range)
     |> assign(:sex, sex)
     |> assign(:hints_enabled, hints_enabled)}
  end

  @impl true
  def handle_event("select", params, socket) do
    parameter = String.to_atom(params["parameter"])
    choice = String.to_atom(params["choice"])
    selections = Map.put(socket.assigns.selections, parameter, {choice, nil})

    {:noreply,
     socket
     |> assign(:selections, selections)
     |> assign(:state, :answering)}
  end

  @impl true
  def handle_event("check_answers", _params, %{assigns: _assigns} = socket) do
    checked_answers = check_answers(socket.assigns)

    socket =
      if full_score?(checked_answers) do
        push_event(socket, "confetti", %{})
      else
        socket
      end

    {:noreply,
     socket
     |> assign(:selections, checked_answers)
     |> assign(:state, :review)}
  end

  @impl true
  def handle_event("next", _params, socket) do
    # Create a fake session from current socket assigns for setup function
    session = %{
      "current_lab" => socket.assigns.lab_module |> Atom.to_string(),
      "current_analyzer" => socket.assigns.analyzer |> Atom.to_string()
    }

    {:noreply, setup(socket, session)}
  end

  defp check_answers(%{
         selections: selections,
         printout: printout,
         lab_module: lab_module,
         age_range: age_range,
         sex: sex
       }) do
    Enum.reduce(selections, %{}, fn {parameter, {choice, _}}, acc ->
      parameter_value = Map.get(printout, parameter)
      context = %{age_range: age_range, sex: sex}

      correct_answer =
        Astrup.check_value_against_reference_range(
          lab_module,
          parameter,
          parameter_value,
          context
        )

      Map.put(acc, parameter, {choice, choice == correct_answer})
    end)
  end

  defp correct_count(selections) do
    selections
    |> Enum.filter(fn {_, {_, correct?}} -> correct? == true end)
    |> length()
  end

  defp total_count(selections), do: map_size(selections)

  defp full_score?(selections) do
    correct_count = correct_count(selections)
    total_count = total_count(selections)
    correct_count == total_count && total_count > 0
  end

  defp number_of_selections_made(selections) do
    selections
    |> Enum.filter(fn {_, {selection, _}} -> not is_nil(selection) end)
    |> length()
  end
end
