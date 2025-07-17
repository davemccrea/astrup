defmodule Astrup.ECG.Datasets.Ptbxl.Query do
  @doc """
  Get ECGs by specific SCP code.
  """
  def get_by_scp_code(records, scp_code, count \\ 1) do
    records
    |> filter_high_quality()
    |> filter_signal_quality()
    |> Enum.filter(&has_scp_code(&1, scp_code))
    |> Enum.shuffle()
    |> Enum.take(count)
  end

  @doc """
  Get the primary diagnosis for a record based on highest confidence SCP code.
  """
  def get_primary_diagnosis(record) do
    case record.scp_codes do
      codes when map_size(codes) == 0 ->
        "OTHER"

      codes ->
        {primary_code, _confidence} =
          Enum.max_by(codes, fn {_code, confidence} -> confidence end)

        case lookup_scp_code(primary_code) do
          {:diagnostic, _description, diagnostic_class} -> diagnostic_class
          _ -> "OTHER"
        end
    end
  end

  def filter_high_quality(records) do
    records
    |> Enum.filter(fn record ->
      (record.strat_fold == 9 or record.strat_fold == 10) and
        record.validated_by_human == true
    end)
  end

  def filter_signal_quality(records) do
    records
    |> Enum.filter(fn record ->
      (record.electrodes_problems == "" or record.electrodes_problems == nil) and
        (record.baseline_drift == "" or record.baseline_drift == nil) and
        (record.pacemaker == "" or record.pacemaker == nil) and
        (record.static_noise == "" or record.static_noise == nil) and
        (record.burst_noise == "" or record.burst_noise == nil)
    end)
  end

  @doc """
  Filter records to only include those that have been validated by a human.
  """
  def filter_human_validated(records) do
    records
    |> Enum.filter(fn record ->
      record.validated_by_human == true
    end)
  end

  @doc """
  Filter records to only include those with at least one diagnosis confidence of 100.
  """
  def filter_confidence_100(records) do
    records
    |> Enum.filter(fn record ->
      Enum.any?(record.scp_codes, fn {_code, confidence} -> confidence == 100.0 end)
    end)
  end

  @doc """
  Filter records to only include those with second opinion validation.
  """
  def filter_second_opinion(records) do
    records
    |> Enum.filter(fn record ->
      record.second_opinion == true
    end)
  end

  @doc """
  Take a specified number of records from each SCP code.
  Groups records by their highest confidence SCP code and takes up to `count` records per code.
  """
  def take_per_scp_code(records, count) do
    records
    |> Enum.group_by(&get_primary_scp_code/1)
    |> Enum.flat_map(fn {_code, records_for_code} ->
      records_for_code
      |> Enum.shuffle()
      |> Enum.take(count)
    end)
  end

  defp get_primary_scp_code(record) do
    case record.scp_codes do
      codes when map_size(codes) == 0 ->
        "OTHER"

      codes ->
        {primary_code, _confidence} =
          Enum.max_by(codes, fn {_code, confidence} -> confidence end)

        primary_code
    end
  end

  defp has_scp_code(record, scp_code) do
    Map.has_key?(record.scp_codes, scp_code)
  end

  @doc """
  Look up SCP code information from the PTB-XL database.
  Returns {:kind, :description, :diagnostic_class} where:
  - :kind is one of :diagnostic, :form, or :rhythm
  - :description is the human-readable description
  - :diagnostic_class is the diagnostic class (only for diagnostic codes, nil otherwise)
  """
  def lookup_scp_code(scp_code) do
    case scp_code do
      "NDT" ->
        {:diagnostic, "non-diagnostic T abnormalities", "STTC"}

      "NST_" ->
        {:diagnostic, "non-specific ST changes", "STTC"}

      "DIG" ->
        {:diagnostic, "digitalis-effect", "STTC"}

      "LNGQT" ->
        {:diagnostic, "long QT-interval", "STTC"}

      "NORM" ->
        {:diagnostic, "normal ECG", "NORM"}

      "IMI" ->
        {:diagnostic, "inferior myocardial infarction", "MI"}

      "ASMI" ->
        {:diagnostic, "anteroseptal myocardial infarction", "MI"}

      "LVH" ->
        {:diagnostic, "left ventricular hypertrophy", "HYP"}

      "LAFB" ->
        {:diagnostic, "left anterior fascicular block", "CD"}

      "ISC_" ->
        {:diagnostic, "non-specific ischemic", "STTC"}

      "IRBBB" ->
        {:diagnostic, "incomplete right bundle branch block", "CD"}

      "1AVB" ->
        {:diagnostic, "first degree AV block", "CD"}

      "IVCD" ->
        {:diagnostic, "non-specific intraventricular conduction disturbance (block)", "CD"}

      "ISCAL" ->
        {:diagnostic, "ischemic in anterolateral leads", "STTC"}

      "CRBBB" ->
        {:diagnostic, "complete right bundle branch block", "CD"}

      "CLBBB" ->
        {:diagnostic, "complete left bundle branch block", "CD"}

      "ILMI" ->
        {:diagnostic, "inferolateral myocardial infarction", "MI"}

      "LAO/LAE" ->
        {:diagnostic, "left atrial overload/enlargement", "HYP"}

      "AMI" ->
        {:diagnostic, "anterior myocardial infarction", "MI"}

      "ALMI" ->
        {:diagnostic, "anterolateral myocardial infarction", "MI"}

      "ISCIN" ->
        {:diagnostic, "ischemic in inferior leads", "STTC"}

      "INJAS" ->
        {:diagnostic, "subendocardial injury in anteroseptal leads", "MI"}

      "LMI" ->
        {:diagnostic, "lateral myocardial infarction", "MI"}

      "ISCIL" ->
        {:diagnostic, "ischemic in inferolateral leads", "STTC"}

      "LPFB" ->
        {:diagnostic, "left posterior fascicular block", "CD"}

      "ISCAS" ->
        {:diagnostic, "ischemic in anteroseptal leads", "STTC"}

      "INJAL" ->
        {:diagnostic, "subendocardial injury in anterolateral leads", "MI"}

      "ISCLA" ->
        {:diagnostic, "ischemic in lateral leads", "STTC"}

      "RVH" ->
        {:diagnostic, "right ventricular hypertrophy", "HYP"}

      "ANEUR" ->
        {:diagnostic, "ST-T changes compatible with ventricular aneurysm", "STTC"}

      "RAO/RAE" ->
        {:diagnostic, "right atrial overload/enlargement", "HYP"}

      "EL" ->
        {:diagnostic, "electrolytic disturbance or drug (former EDIS)", "STTC"}

      "WPW" ->
        {:diagnostic, "Wolf-Parkinson-White syndrome", "CD"}

      "ILBBB" ->
        {:diagnostic, "incomplete left bundle branch block", "CD"}

      "IPLMI" ->
        {:diagnostic, "inferoposterolateral myocardial infarction", "MI"}

      "ISCAN" ->
        {:diagnostic, "ischemic in anterior leads", "STTC"}

      "IPMI" ->
        {:diagnostic, "inferoposterior myocardial infarction", "MI"}

      "SEHYP" ->
        {:diagnostic, "septal hypertrophy", "HYP"}

      "INJIN" ->
        {:diagnostic, "subendocardial injury in inferior leads", "MI"}

      "INJLA" ->
        {:diagnostic, "subendocardial injury in lateral leads", "MI"}

      "PMI" ->
        {:diagnostic, "posterior myocardial infarction", "MI"}

      "3AVB" ->
        {:diagnostic, "third degree AV block", "CD"}

      "INJIL" ->
        {:diagnostic, "subendocardial injury in inferolateral leads", "MI"}

      "2AVB" ->
        {:diagnostic, "second degree AV block", "CD"}

      "ABQRS" ->
        {:form, "abnormal QRS", nil}

      "PVC" ->
        {:form, "ventricular premature complex", nil}

      "STD_" ->
        {:form, "non-specific ST depression", nil}

      "VCLVH" ->
        {:form, "voltage criteria (QRS) for left ventricular hypertrophy", nil}

      "QWAVE" ->
        {:form, "Q waves present", nil}

      "LOWT" ->
        {:form, "low amplitude T-waves", nil}

      "NT_" ->
        {:form, "non-specific T-wave changes", nil}

      "PAC" ->
        {:form, "atrial premature complex", nil}

      "LPR" ->
        {:form, "prolonged PR interval", nil}

      "INVT" ->
        {:form, "inverted T-waves", nil}

      "LVOLT" ->
        {:form, "low QRS voltages in the frontal and horizontal leads", nil}

      "HVOLT" ->
        {:form, "high QRS voltage", nil}

      "TAB_" ->
        {:form, "T-wave abnormality", nil}

      "STE_" ->
        {:form, "non-specific ST elevation", nil}

      "PRC(S)" ->
        {:form, "premature complex(es)", nil}

      "SR" ->
        {:rhythm, "sinus rhythm", nil}

      "AFIB" ->
        {:rhythm, "atrial fibrillation", nil}

      "STACH" ->
        {:rhythm, "sinus tachycardia", nil}

      "SARRH" ->
        {:rhythm, "sinus arrhythmia", nil}

      "SBRAD" ->
        {:rhythm, "sinus bradycardia", nil}

      "PACE" ->
        {:rhythm, "normal functioning artificial pacemaker", nil}

      "SVARR" ->
        {:rhythm, "supraventricular arrhythmia", nil}

      "BIGU" ->
        {:rhythm, "bigeminal pattern (unknown origin, SV or Ventricular)", nil}

      "AFLT" ->
        {:rhythm, "atrial flutter", nil}

      "SVTAC" ->
        {:rhythm, "supraventricular tachycardia", nil}

      "PSVT" ->
        {:rhythm, "paroxysmal supraventricular tachycardia", nil}

      "TRIGU" ->
        {:rhythm, "trigeminal pattern (unknown origin, SV or Ventricular)", nil}

      _ ->
        nil
    end
  end

  @doc """
  Get the primary rhythm from SCP codes. Since rhythm confidence is always 0 in PTB-XL,
  returns the first rhythm code found.
  """
  def get_rhythm_from_scp_codes([]), do: nil

  def get_rhythm_from_scp_codes(scp_codes) do
    scp_codes
    |> Enum.filter(&(&1.kind == :rhythm))
    |> List.first()
    |> case do
      nil -> nil
      %{description: description} -> description
    end
  end

  @doc """
  Extracts metadata from a PTB-XL record in standardized format.
  """
  def get_metadata(record) do
    scp_codes_with_descriptions =
      record.scp_codes
      |> Enum.map(&build_scp_code_metadata/1)
      |> Enum.sort_by(& &1.confidence, :desc)

    %{
      type: :ptbxl,
      scp_codes: scp_codes_with_descriptions,
      report: record.report,
      age: record.age,
      sex: record.sex,
      height: record.height,
      weight: record.weight,
      recording_date: record.recording_date,
      device: record.device,
      heart_axis: record.heart_axis,
      validated_by_human: record.validated_by_human
    }
  end

  defp build_scp_code_metadata({code, confidence}) do
    case lookup_scp_code(code) do
      {kind, description, diagnostic_class} ->
        %{
          code: code,
          confidence: confidence,
          kind: kind,
          description: description,
          diagnostic_class: diagnostic_class
        }

      nil ->
        %{
          code: code,
          confidence: confidence,
          kind: :unknown,
          description: "Unknown SCP code",
          diagnostic_class: nil
        }
    end
  end
end
