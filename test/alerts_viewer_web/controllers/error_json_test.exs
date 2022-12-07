defmodule AlertsViewerWeb.ErrorJSONTest do
  use AlertsViewerWeb.ConnCase, async: true

  test "renders 404" do
    assert AlertsViewerWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert AlertsViewerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
