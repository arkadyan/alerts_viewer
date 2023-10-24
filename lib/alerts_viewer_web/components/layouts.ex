defmodule AlertsViewerWeb.Layouts do
  @moduledoc """
  Render page layouts.
  """

  use AlertsViewerWeb, :html

  embed_templates "layouts/*"

  def google_tag_manager_id do
    case Application.get_env(:alerts_viewer, :google_tag_manager_id, "") do
      "" -> nil
      id -> id
    end
  end
end
