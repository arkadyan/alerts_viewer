defmodule PredictionResults do
  @moduledoc """
  Defines a collection of prediction results, and what those types can be: true positive, true negative, false positive, or false negative. Enables statistical opperations on the results.
  """

  @typedoc """
  The reseult of a single prediction. True positive, true negative, false
  positive, or false negative.
  """
  @type result :: :tp | :tn | :fp | :fn

  @type t :: [result()]

  @doc """
  Generate PredictionResults from a list of predictions and a list of targets.

  iex> PredictionResults.new([true, false, true, false], [true, false, false, true])
  [:tp, :tn, :fp, :fn]
  """
  @spec new([boolean()], [boolean()]) :: t()
  def new(predictions, targets) do
    [predictions, targets]
    |> List.zip()
    |> Enum.map(&to_result/1)
  end

  @doc """
  An accuracy measure that normalizes true positive
  and true negative predictions by the number of
  positive and negative samples, respectively,
  and divides their sum by two.

  Formula: ((TP/ TP+FN) + (TN / TN+FP)) / 2
  or alternately: (recall + specificity) / 2

  iex> PredictionResults.balanced_accuracy([:tp, :tp, :tn, :fp, :fp, :fn])
  50
  """
  @spec balanced_accuracy(t()) :: non_neg_integer()
  def balanced_accuracy(results) do
    recall = recall(results)
    specificity = specificity(results)
    ((recall + specificity) / 2) |> round
  end

  @doc """
  The harmonic mean of recall and precision
  Formula: ((precision * recall)/(precision + recall)) * 2

  iex> PredictionResults.f_measure([:tp, :tp, :tn, :fp, :fp, :fn])
  57
  """
  @spec f_measure(t()) :: non_neg_integer()
  def f_measure(results) do
    recall = recall(results)
    precision = precision(results)

    case precision > 0 and recall > 0 do
      true -> (precision * recall / (precision + recall) * 2) |> round
      false -> 0
    end
  end

  @doc """
  The percentage of all data points in the target class that were correctly
  identified as not belonging to the target class. Rounded to the nearest whole
  number.

  Formula: TN / TN+FP

  iex> PredictionResults.recall([:tp, :tn, :fp, :fn])
  50
  """
  @spec specificity(t()) :: non_neg_integer()
  def specificity(results) do
    true_negative_count = Enum.count(results, &true_negative?/1)
    false_positive_count = Enum.count(results, &false_positive?/1)

    rounded_percent(true_negative_count, true_negative_count + false_positive_count)
  end

  @doc """
  The percentage of all data points in the target class that were correctly
  identified as belonging to the target class. Rounded to the nearest whole
  number.

  Formula: TP / TP+FN

  iex> PredictionResults.recall([:tp, :tn, :fp, :fn])
  50
  """
  @spec recall(t()) :: non_neg_integer()
  def recall(results) do
    true_positive_count = Enum.count(results, &true_positive?/1)
    false_negative_count = Enum.count(results, &false_negative?/1)

    rounded_percent(true_positive_count, true_positive_count + false_negative_count)
  end

  @doc """
  How many of the cases predicted to belong to the target class actually belong
  to the target class. Rounded to the nearest whole number.

  Formula: TP / TP+FP

  iex> PredictionResults.precision([:tp, :tn, :fp, :fn])
  50
  """
  @spec precision(t()) :: non_neg_integer()
  def precision(results) do
    true_positive_count = Enum.count(results, &true_positive?/1)
    false_positive_count = Enum.count(results, &false_positive?/1)

    rounded_percent(true_positive_count, true_positive_count + false_positive_count)
  end

  @doc """
  Convert a result or a result-target pair to a string label.

  iex> PredictionResults.to_string(:tp)
  "TP"
  iex> PredictionResults.to_string(true, true)
  "TP"
  """
  @spec to_string(result()) :: String.t()
  @spec to_string(boolean(), boolean()) :: String.t()
  def to_string(:tp), do: "TP"
  def to_string(:tn), do: "TN"
  def to_string(:fp), do: "FP"
  def to_string(:fn), do: "FN"

  def to_string(preduction, target) do
    {preduction, target}
    |> to_result()
    |> PredictionResults.to_string()
  end

  @spec to_result({boolean(), boolean()}) :: result()
  defp to_result({true, true}), do: :tp
  defp to_result({false, false}), do: :tn
  defp to_result({true, false}), do: :fp
  defp to_result({false, true}), do: :fn

  @spec true_result?(result()) :: boolean()
  @spec true_result?(boolean(), boolean()) :: boolean()
  defp true_result?(result) when result in [:tp, :tn], do: true
  defp true_result?(_), do: false

  def true_result?(preduction, target) do
    {preduction, target}
    |> to_result()
    |> true_result?()
  end

  @spec true_positive?(result()) :: boolean()
  defp true_positive?(:tp), do: true
  defp true_positive?(_), do: false

  @spec false_positive?(result()) :: boolean()
  defp false_positive?(:fp), do: true
  defp false_positive?(_), do: false

  @spec true_negative?(result()) :: boolean()
  defp true_negative?(:tn), do: true
  defp true_negative?(_), do: false

  @spec false_negative?(result()) :: boolean()
  defp false_negative?(:fn), do: true
  defp false_negative?(_), do: false

  @spec rounded_percent(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp rounded_percent(_num, 0), do: 0
  defp rounded_percent(num, denom), do: round(num / denom * 100)
end
