defmodule AlertsViewerWeb.PageController do
  use AlertsViewerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
