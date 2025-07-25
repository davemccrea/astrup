defmodule AstrupWeb.Interpretation.QuizLive do
  @moduledoc """
  Case-based ABG interpretation quiz where users are presented with clinical scenarios
  and asked to classify parameters and provide interpretations.
  """
  use AstrupWeb, :live_view

  alias Astrup.PatientCase

  @type state :: :ready | :answering | :review

  def mount(_, session, socket) do
    current_lab = session["current_lab"] || "Astrup.Lab.Fimlab"
    lab_module = Module.concat([current_lab])
    current_analyzer = session["current_analyzer"] || "Astrup.Analyzer.RadiometerAbl90FlexPlus"
    analyzer = Module.concat([current_analyzer])

    socket =
      socket
      |> assign(:show_reference_values, false)
      |> assign(:lab_module, lab_module)
      |> assign(:analyzer, analyzer)

    {:ok, setup_new_case(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} locale={@locale} current_scope={@current_scope}>
      <div class="container mx-auto px-2 sm:px-4 py-4 sm:py-8">
        <div class="mb-8">
          <h1 class="text-2xl sm:text-3xl font-bold mb-4">
            {gettext("ABG Interpreation Quiz")}
          </h1>
          <p class="text-base-content/70 mb-6">
            {gettext("Practice interpreting ABG results with clinical cases")}
          </p>
          
    <!-- Navigation back to Learn -->
          <div class="mb-8">
            <.link navigate={~p"/interpretation/learn"} class="btn btn-primary">
              <.icon name="hero-arrow-left" class="w-5 h-5" />
              {gettext("Back to Learning")}
            </.link>
          </div>
        </div>

        <div class="flex flex-col lg:flex-row gap-6 max-w-7xl mx-auto">
          <!-- Sidebar Section -->
          <div class="w-full lg:w-80 lg:sticky lg:top-4 lg:self-start space-y-4 order-1 lg:order-1">
            <%= if @state == :review do %>
              <.score_section score={@score} total={5} />
            <% end %>

            <section class="border border-base-content/20 shadow p-4">
              <h2 class="text-lg font-semibold mb-3 text-primary">{gettext("Instructions")}</h2>
              <p class="mb-4">
                {gettext(
                  "Read the clinical presentation, classify each parameter, and select the most appropriate interpretation."
                )}
              </p>

              <div class="flex flex-col gap-3">
                <button
                  class="btn btn-primary gap-2 w-full"
                  phx-click="check_answers"
                  disabled={
                    @state == :review or
                      not all_selections_made?(
                        @selections,
                        @selected_primary_disorder,
                        @selected_compensation
                      )
                  }
                >
                  {gettext("Check Answers")}
                </button>

                <button
                  class="btn btn-secondary gap-2 w-full"
                  phx-click="next_case"
                  disabled={@state != :review}
                >
                  {gettext("Next Case")}
                  <.icon name="hero-arrow-right" class="w-4 h-4" />
                </button>
              </div>

              <div class="divider"></div>

              <.form for={%{}} phx-change="toggle_reference_values">
                <.input
                  type="checkbox"
                  name="show_reference_values"
                  label={gettext("Show ABG Reference Values")}
                  checked={@show_reference_values}
                  class="checkbox checkbox-sm"
                />
              </.form>
            </section>
          </div>
          
    <!-- Main Content Section -->
          <div class="w-full lg:flex-1 order-2 lg:order-2 space-y-6">
            <!-- Explanation (shown after checking answers) -->
            <%= if @state == :review do %>
              <div class="border border-base-content/20 shadow p-6 mb-6 bg-base-100">
                <h2 class="text-lg font-semibold text-primary mb-4 flex items-center gap-2">
                  <.icon name="hero-academic-cap" class="w-5 h-5" />
                  {gettext("Explanation")}
                </h2>
                <div class="max-w-none">
                  {@case_data.explanation}
                </div>
              </div>
            <% end %>
            
    <!-- Results Comparison Table (shown after checking answers) -->
            <%= if @state == :review do %>
              <.results_comparison_table
                score={@score}
                selections={@selections}
                correct_parameter_classifications={@correct_parameter_classifications}
                primary_disorder_correct={@primary_disorder_correct}
                compensation_correct={@compensation_correct}
                selected_primary_disorder={@selected_primary_disorder}
                selected_compensation={@selected_compensation}
                correct_primary_disorder={@correct_primary_disorder}
                correct_compensation={@correct_compensation}
              />
            <% end %>
            
    <!-- Case Interpretation -->
            <div class="border border-base-content/20 shadow p-6 space-y-8">
              <!-- Clinical Presentation -->
              <div>
                <h2 class="text-lg font-semibold mb-4 text-primary">
                  {gettext("Clinical Presentation")}
                </h2>
                <div class="max-w-none">
                  {@case_summary}
                </div>
              </div>

              <div class="divider"></div>
              
    <!-- ABG Interpreation -->
              <div>
                <h2 class="text-lg font-semibold mb-4 text-primary">
                  {gettext("ABG Interpreation")}
                </h2>
                <div class="flex items-center gap-3 mb-4">
                  <div class="badge badge-primary badge-lg font-bold">1</div>
                  <p class="text-base font-medium">
                    {gettext("Classify each parameter as acidosis, normal, or alkalosis:")}
                  </p>
                </div>

                <div class="space-y-4">
                  <!-- Main parameters for classification -->
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <.parameter_card
                      parameter={:ph}
                      value={@case_data.ph}
                      selection={@selections.ph}
                      disabled={@state == :review}
                      show_reference_values={@show_reference_values}
                      case_data={@case_data}
                      correct_selection={
                        if @state == :review,
                          do: Map.get(@correct_parameter_classifications, :ph),
                          else: nil
                      }
                    />
                    <.parameter_card
                      parameter={:pco2}
                      value={@case_data.pco2}
                      selection={@selections.pco2}
                      disabled={@state == :review}
                      show_reference_values={@show_reference_values}
                      case_data={@case_data}
                      correct_selection={
                        if @state == :review,
                          do: Map.get(@correct_parameter_classifications, :pco2),
                          else: nil
                      }
                    />
                    <.parameter_card
                      parameter={:bicarbonate}
                      value={@case_data.bicarbonate}
                      selection={@selections.bicarbonate}
                      disabled={@state == :review}
                      show_reference_values={@show_reference_values}
                      case_data={@case_data}
                      correct_selection={
                        if @state == :review,
                          do: Map.get(@correct_parameter_classifications, :bicarbonate),
                          else: nil
                      }
                    />
                  </div>
                  
    <!-- Reference parameters -->
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.parameter_display
                      parameter={:po2}
                      value={@case_data.po2}
                      show_reference_values={@show_reference_values}
                      case_data={@case_data}
                    />
                    <.parameter_display
                      parameter={:base_excess}
                      value={@case_data.base_excess}
                      show_reference_values={@show_reference_values}
                      case_data={@case_data}
                    />
                  </div>
                </div>
              </div>

              <%= if @state != :review do %>
                <div class="space-y-6">
                  <!-- Step 2: Primary Problem -->
                  <div>
                    <div class="flex items-center gap-3 mb-4">
                      <div class="badge badge-primary badge-lg font-bold">2</div>
                      <p class="text-base font-medium">
                        {gettext("Identify the primary acid-base disorder:")}
                      </p>
                    </div>

                    <.form for={%{}} phx-change="select_primary_disorder">
                      <.input
                        type="select"
                        name="primary_disorder"
                        value={@selected_primary_disorder}
                        prompt={gettext("Choose primary disorder...")}
                        options={@primary_disorder_options}
                      />
                    </.form>
                  </div>
                  
    <!-- Step 3: Compensation -->
                  <div>
                    <div class="flex items-center gap-3 mb-4">
                      <div class="badge badge-primary badge-lg font-bold">3</div>
                      <p class="text-base font-medium">
                        {gettext("Determine the level of compensation:")}
                      </p>
                    </div>

                    <.form for={%{}} phx-change="select_compensation">
                      <.input
                        type="select"
                        name="compensation"
                        value={@selected_compensation}
                        prompt={gettext("Choose compensation level...")}
                        options={@compensation_options}
                        disabled={
                          @selected_primary_disorder == nil or
                            @selected_primary_disorder == :normal
                        }
                      />
                    </.form>
                  </div>
                </div>
              <% end %>

              <div class="mt-8 pt-4 border-t border-base-content/10">
                <p class="text-xs text-base-content/60 italic">
                  {gettext(
                    "Note: Mixed acid-base disorders and fully compensated conditions exist in clinical practice but are not addressed here for educational simplicity."
                  )}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Parameter card component
  attr :parameter, :atom, required: true
  attr :value, :any, required: true
  attr :selection, :atom, default: nil
  attr :disabled, :boolean, default: false
  attr :show_reference_values, :boolean, default: false
  attr :case_data, :map, required: true
  attr :correct_selection, :atom, default: nil

  def parameter_card(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-sm">
      <div class="card-body">
        <h3 class="card-title text-sm">
          {parameter_name(@parameter)}
          <%= if @show_reference_values do %>
            <span class="text-xs font-normal text-base-content/50">
              ({get_fimlab_reference_range(@parameter, @case_data)})
            </span>
          <% end %>
        </h3>
        <div class="stat-value text-lg font-mono text-primary">
          {format_value(@value, @parameter)}
        </div>

        <%= if not @disabled do %>
          <div class="card-actions justify-start mt-4">
            <div class="flex flex-wrap gap-2">
              <button
                type="button"
                class={[
                  "btn btn-sm",
                  if(@selection == :acidosis, do: "btn-error btn-active", else: "btn-outline")
                ]}
                phx-click="select_parameter"
                phx-value-parameter={@parameter}
                phx-value-selection="acidosis"
              >
                {gettext("Acidosis")}
              </button>

              <button
                type="button"
                class={[
                  "btn btn-sm",
                  if(@selection == :normal, do: "btn-success btn-active", else: "btn-outline")
                ]}
                phx-click="select_parameter"
                phx-value-parameter={@parameter}
                phx-value-selection="normal"
              >
                {gettext("Normal")}
              </button>

              <button
                type="button"
                class={[
                  "btn btn-sm",
                  if(@selection == :alkalosis, do: "btn-info btn-active", else: "btn-outline")
                ]}
                phx-click="select_parameter"
                phx-value-parameter={@parameter}
                phx-value-selection="alkalosis"
              >
                {gettext("Alkalosis")}
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Results comparison table component
  attr :selections, :map, required: true
  attr :correct_parameter_classifications, :map, required: true
  attr :primary_disorder_correct, :boolean, required: true
  attr :compensation_correct, :boolean, required: true
  attr :selected_primary_disorder, :string, default: nil
  attr :selected_compensation, :string, default: nil
  attr :correct_primary_disorder, :string, required: true
  attr :correct_compensation, :string, default: nil
  attr :score, :integer, required: true

  def results_comparison_table(assigns) do
    ~H"""
    <div class="border border-base-content/20 shadow p-6 mb-6 bg-base-100">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold text-primary flex items-center gap-2">
          <.icon name="hero-clipboard-document-check" class="w-5 h-5" />
          {gettext("Results")}
        </h2>
        <div class="text-right">
          <div class="stat-value text-xl">
            <span class={if @score >= 4, do: "text-success", else: "text-warning"}>
              {@score}/5
            </span>
          </div>
          <%= if @score == 5 do %>
            <div class="text-sm text-success font-semibold">
              {gettext("Perfect!")} 🎉
            </div>
          <% end %>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="table table-zebra w-full">
          <thead>
            <tr>
              <th>{gettext("Parameter")}</th>
              <th>{gettext("Your Answer")}</th>
              <th>{gettext("Correct")}</th>
              <th class="text-center">{gettext("Result")}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{param, user_selection} <- @selections}>
              <td class="font-medium">{parameter_name(param)}</td>
              <td>
                <span class={[
                  "badge badge-sm",
                  case user_selection do
                    :acidosis -> "badge-error"
                    :normal -> "badge-success"
                    :alkalosis -> "badge-info"
                  end
                ]}>
                  {classification_label(user_selection)}
                </span>
              </td>
              <td>
                <span class={[
                  "badge badge-sm",
                  case Map.get(@correct_parameter_classifications, param) do
                    :acidosis -> "badge-error"
                    :normal -> "badge-success"
                    :alkalosis -> "badge-info"
                  end
                ]}>
                  {classification_label(Map.get(@correct_parameter_classifications, param))}
                </span>
              </td>
              <td class="text-center">
                <%= if Map.get(@correct_parameter_classifications, param) == user_selection do %>
                  <.icon name="hero-check" class="w-5 h-5 text-success" />
                <% else %>
                  <.icon name="hero-x-mark" class="w-5 h-5 text-error" />
                <% end %>
              </td>
            </tr>
            <tr>
              <td class="font-medium">{gettext("Primary Disorder")}</td>
              <td>
                <span class="text-sm">
                  {primary_disorder_label(@selected_primary_disorder) || gettext("No selection")}
                </span>
              </td>
              <td>
                <span class="text-sm">
                  {primary_disorder_label(@correct_primary_disorder)}
                </span>
              </td>
              <td class="text-center">
                <%= if @primary_disorder_correct do %>
                  <.icon name="hero-check" class="w-5 h-5 text-success" />
                <% else %>
                  <.icon name="hero-x-mark" class="w-5 h-5 text-error" />
                <% end %>
              </td>
            </tr>
            <%= if @correct_compensation do %>
              <tr>
                <td class="font-medium">{gettext("Compensation")}</td>
                <td>
                  <span class="text-sm">
                    {compensation_label(@selected_compensation) || gettext("No selection")}
                  </span>
                </td>
                <td>
                  <span class="text-sm">
                    {compensation_label(@correct_compensation)}
                  </span>
                </td>
                <td class="text-center">
                  <%= if @compensation_correct do %>
                    <.icon name="hero-check" class="w-5 h-5 text-success" />
                  <% else %>
                    <.icon name="hero-x-mark" class="w-5 h-5 text-error" />
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Parameter display component (shows value without classification buttons)
  attr :parameter, :atom, required: true
  attr :value, :any, required: true
  attr :show_reference_values, :boolean, default: false
  attr :case_data, :map, required: true

  def parameter_display(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-sm">
      <div class="card-body">
        <h3 class="card-title text-sm">
          {parameter_name(@parameter)}
          <%= if @show_reference_values do %>
            <span class="text-xs font-normal opacity-60">
              ({get_fimlab_reference_range(@parameter, @case_data)})
            </span>
          <% end %>
        </h3>
        <div class="stat-value text-lg font-mono text-primary">
          {format_value(@value, @parameter)}
        </div>

        <div class="card-actions justify-start mt-4">
          <div class="text-xs">
            {gettext("ABG Reference Values")}
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event handlers
  def handle_event("select_parameter", %{"parameter" => param, "selection" => selection}, socket) do
    parameter = String.to_atom(param)
    selection_atom = String.to_atom(selection)

    new_selections = Map.put(socket.assigns.selections, parameter, selection_atom)

    {:noreply, assign(socket, :selections, new_selections)}
  end

  def handle_event("select_primary_disorder", %{"primary_disorder" => disorder}, socket) do
    disorder_value = if disorder == "", do: nil, else: String.to_atom(disorder)

    # Reset compensation if primary disorder changes
    socket =
      socket
      |> assign(:selected_primary_disorder, disorder_value)
      |> assign(:selected_compensation, nil)

    {:noreply, socket}
  end

  def handle_event("select_compensation", %{"compensation" => compensation}, socket) do
    compensation_value = if compensation == "", do: nil, else: String.to_atom(compensation)
    {:noreply, assign(socket, :selected_compensation, compensation_value)}
  end

  def handle_event("check_answers", _params, socket) do
    # Calculate score and show results
    socket =
      socket
      |> calculate_score()
      |> assign(:state, :review)

    {:noreply, socket}
  end

  def handle_event("next_case", _params, socket) do
    {:noreply, setup_new_case(socket)}
  end

  def handle_event("toggle_reference_values", %{"show_reference_values" => "true"}, socket) do
    {:noreply, assign(socket, :show_reference_values, true)}
  end

  def handle_event("toggle_reference_values", _params, socket) do
    {:noreply, assign(socket, :show_reference_values, false)}
  end

  # Helper functions
  defp setup_new_case(socket) do
    case_data = PatientCase.get_random_case()

    if case_data do
      socket
      |> assign(:state, :ready)
      |> assign(:case_data, case_data)
      |> assign(:case_summary, case_data.quiz_description)
      |> assign(:selections, %{ph: nil, pco2: nil, bicarbonate: nil})
      |> assign(:selected_primary_disorder, nil)
      |> assign(:selected_compensation, nil)
      |> assign(:primary_disorder_options, get_primary_disorder_options())
      |> assign(:compensation_options, get_compensation_options())
      |> assign(:correct_primary_disorder, case_data.primary_disorder)
      |> assign(:correct_compensation, case_data.compensation)
      |> assign(:score, 0)
      |> assign(:show_reference_values, true)
    else
      # Fallback if no cases in database
      socket
      |> put_flash(:error, "No cases available. Please contact administrator.")
      |> assign(:state, :ready)
    end
  end

  defp get_primary_disorder_options do
    [
      {gettext("Normal acid-base balance"), :normal},
      {gettext("Respiratory acidosis"), :respiratory_acidosis},
      {gettext("Respiratory alkalosis"), :respiratory_alkalosis},
      {gettext("Metabolic acidosis"), :metabolic_acidosis},
      {gettext("Metabolic alkalosis"), :metabolic_alkalosis}
    ]
  end

  defp get_compensation_options do
    [
      {gettext("Uncompensated"), :uncompensated},
      {gettext("Partially compensated"), :partially_compensated}
    ]
  end

  defp all_selections_made?(selections, selected_primary_disorder, selected_compensation) do
    required_params = [:ph, :pco2, :bicarbonate]
    all_params_selected = Enum.all?(required_params, &(Map.get(selections, &1) != nil))
    primary_disorder_selected = selected_primary_disorder != nil

    # Compensation is only required if the primary disorder is not normal
    compensation_required = selected_primary_disorder not in [:normal, nil]
    compensation_selected = selected_compensation != nil or not compensation_required

    all_params_selected and primary_disorder_selected and compensation_selected
  end

  defp calculate_score(socket) do
    case_data = socket.assigns.case_data
    selections = socket.assigns.selections
    selected_primary_disorder = socket.assigns.selected_primary_disorder
    selected_compensation = socket.assigns.selected_compensation
    correct_primary_disorder = socket.assigns.correct_primary_disorder
    correct_compensation = socket.assigns.correct_compensation

    # Calculate correct parameter classifications
    correct_classifications = get_correct_classifications(case_data)

    # Count correct parameter classifications (3 parameters)
    parameter_score =
      Enum.count(selections, fn {param, user_selection} ->
        Map.get(correct_classifications, param) == user_selection
      end)

    # Check primary disorder (1 point)
    primary_disorder_correct = selected_primary_disorder == correct_primary_disorder
    primary_disorder_score = if primary_disorder_correct, do: 1, else: 0

    # Check compensation (1 point) - only if compensation is expected
    compensation_score =
      cond do
        # No compensation expected, automatic point
        correct_compensation == nil -> 1
        selected_compensation == correct_compensation -> 1
        true -> 0
      end

    total_score = parameter_score + primary_disorder_score + compensation_score

    socket
    |> assign(:score, total_score)
    |> assign(:correct_parameter_classifications, correct_classifications)
    |> assign(:primary_disorder_correct, primary_disorder_correct)
    |> assign(:compensation_correct, selected_compensation == correct_compensation)
  end

  defp parameter_name(parameter) do
    case parameter do
      :ph -> "pH"
      :pco2 -> "pCO₂"
      :po2 -> "pO₂"
      :bicarbonate -> "HCO₃⁻"
      :base_excess -> "Base Excess"
    end
  end

  defp format_value(value, parameter) do
    formatted =
      Decimal.round(
        value,
        case parameter do
          :ph -> 2
          :pco2 -> 1
          :po2 -> 1
          :bicarbonate -> 0
          :base_excess -> 1
        end
      )

    unit =
      case parameter do
        :ph -> ""
        :pco2 -> " kPa"
        :po2 -> " kPa"
        :bicarbonate -> " mmol/L"
        :base_excess -> " mmol/L"
      end

    "#{formatted}#{unit}"
  end

  defp classification_label(:acidosis), do: gettext("Acidosis")
  defp classification_label(:normal), do: gettext("Normal")
  defp classification_label(:alkalosis), do: gettext("Alkalosis")

  defp primary_disorder_label(:normal), do: gettext("Normal acid-base balance")
  defp primary_disorder_label(:respiratory_acidosis), do: gettext("Respiratory acidosis")
  defp primary_disorder_label(:respiratory_alkalosis), do: gettext("Respiratory alkalosis")
  defp primary_disorder_label(:metabolic_acidosis), do: gettext("Metabolic acidosis")
  defp primary_disorder_label(:metabolic_alkalosis), do: gettext("Metabolic alkalosis")
  defp primary_disorder_label(nil), do: nil

  defp compensation_label(:uncompensated), do: gettext("Uncompensated")
  defp compensation_label(:partially_compensated), do: gettext("Partially compensated")
  defp compensation_label(nil), do: nil

  defp get_fimlab_reference_range(parameter, case_data) do
    # Create context based on case data
    context = %{
      age_range: get_age_group(case_data.age),
      sex: case_data.sex
    }

    # Get the reference range from Fimlab
    Astrup.pretty_print_reference_range(Astrup.Lab.Fimlab, parameter, context)
  end

  # Private functions moved from Astrup.Interpreter for better organization

  defp get_correct_classifications(case_data) do
    context = %{age_range: categorize_age(case_data.age), sex: case_data.sex}

    checks =
      Astrup.check_values_against_reference_range(
        Astrup.Lab.Fimlab,
        %{
          ph: case_data.ph,
          pco2: case_data.pco2,
          bicarbonate: case_data.bicarbonate
        },
        context
      )

    %{
      ph: classify_ph_value(checks.ph),
      pco2: classify_respiratory_value(checks.pco2),
      bicarbonate: classify_metabolic_value(checks.bicarbonate)
    }
  end

  defp get_age_group(age) do
    categorize_age(age)
  end

  defp categorize_age(age) do
    cond do
      age <= 18 -> "0-18"
      age <= 30 -> "18-30"
      age <= 50 -> "31-50"
      age <= 60 -> "51-60"
      age <= 70 -> "61-70"
      age <= 80 -> "71-80"
      true -> ">80"
    end
  end

  defp classify_ph_value(:low), do: :acidosis
  defp classify_ph_value(:normal), do: :normal
  defp classify_ph_value(:high), do: :alkalosis

  defp classify_respiratory_value(:low), do: :alkalosis
  defp classify_respiratory_value(:normal), do: :normal
  defp classify_respiratory_value(:high), do: :acidosis

  defp classify_metabolic_value(:low), do: :acidosis
  defp classify_metabolic_value(:normal), do: :normal
  defp classify_metabolic_value(:high), do: :alkalosis
end
