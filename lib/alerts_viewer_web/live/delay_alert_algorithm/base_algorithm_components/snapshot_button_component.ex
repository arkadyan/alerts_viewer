defmodule AlertsViewer.DelayAlertAlgorithm.BaseAlgorithmComponents.SnapshotButtonComponent do
  @moduledoc """
  Component for snapshot buttons in algorithm components. Takes a module name as an attribute.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AlertsViewerWeb.Endpoint,
    router: AlertsViewerWeb.Router,
    statics: AlertsViewerWeb.static_paths()

  attr :module_name, :string, required: true

  def snapshot_button(assigns) do
    ~H"""
    <.link
      navigate={~p"/bus/snapshot/#{@module_name}"}
      replace={false}
      target="_blank"
      class="bg-transparent hover:bg-zinc-500 text-zinc-700 font-semibold hover:text-white py-2 px-4 border border-zinc-500 hover:border-transparent hover:no-underline rounded"
    >
      Snapshot
    </.link>
    """
  end
end
