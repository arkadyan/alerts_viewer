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
  The percentage of all predictions that were correct. Rounded to the nearest
  whole number.

  Formula: TP+TN / TP+TN+FP+FN

  iex> PredictionResults.accuracy([:tp, :tn, :fp, :fn])
  50
  """
  @spec accuracy(t()) :: non_neg_integer()
  def accuracy(results) do
    true_count = Enum.count(results, &true_result?/1)

    rounded_percent(true_count, length(results))
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

  @spec false_negative?(result()) :: boolean()
  defp false_negative?(:fn), do: true
  defp false_negative?(_), do: false

  @spec rounded_percent(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp rounded_percent(_num, 0), do: 0
  defp rounded_percent(num, denom), do: round(num / denom * 100)
end
