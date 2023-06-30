defmodule TripUpdates.GTFSSupervisor do
  @moduledoc """
  Supervisor for realtime tripupdate information from realtime GTFS.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    trip_updates_url =
      Keyword.get(
        opts,
        :trip_updates_url,
        Application.get_env(:alerts_viewer, :trip_updates_url)
      )

    source =
      http_source(
        :trip_updates,
        trip_updates_url,
        TripUpdates.Parser.GTFSRealtimeEnhanced,
        headers: %{},
        params: %{}
      )

    consumer =
      Supervisor.child_spec(
        {TripUpdates.TripUpdates, subscribe_to: [{:trip_updates, [max_demand: 1]}]},
        []
      )

    Supervisor.init([source, consumer], strategy: :one_for_one)
  end

  @spec http_source(term(), String.t(), module(), keyword()) :: Supervisor.child_spec()
  defp http_source(source, url, parser, opts) do
    Supervisor.child_spec(
      {
        HttpProducer,
        {url, [name: source, parser: parser] ++ opts}
      },
      id: source
    )
  end
end
