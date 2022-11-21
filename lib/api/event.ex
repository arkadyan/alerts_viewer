defmodule Api.Event do
  @moduledoc """
  Struct representing a parsed Api server-sent event.
  """

  alias Api.JsonApi

  @type t :: %__MODULE__{
          event: event(),
          data: JsonApi.t() | {:error, any}
        }

  @type event :: :reset | :add | :update | :remove

  @enforce_keys [:event, :data]

  defstruct [
    :event,
    :data
  ]
end
