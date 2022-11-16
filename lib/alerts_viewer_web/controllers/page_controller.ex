defmodule AlertsViewerWeb.PageController do
  use AlertsViewerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
