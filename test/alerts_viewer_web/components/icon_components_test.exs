defmodule AlertsViewerWeb.IconComponentsTest do
  use ExUnit.Case, async: true

  import AlertsViewerWeb.IconComponents

  describe "icon/1" do
    test "generates an svg or a stylized span element for the requested icon type" do
      assert_rendered(mode_icon(%{type: "Red"}), "<svg")
      assert_rendered(mode_icon(%{type: "Blue"}), "<svg")
      assert_rendered(mode_icon(%{type: "Orange"}), "<svg")
      assert_rendered(mode_icon(%{type: "Green-B"}), "<svg")
      assert_rendered(mode_icon(%{type: "Green-C"}), "<svg")
      assert_rendered(mode_icon(%{type: "Green-D"}), "<svg")
      assert_rendered(mode_icon(%{type: "Green-D"}), "<svg")
      assert_rendered(mode_icon(%{type: "Green"}), "<svg")
      assert_rendered(mode_icon(%{type: "Mattapan"}), "<svg")
      assert_rendered(mode_icon(%{type: "using_escalator"}), "<svg")
      assert_rendered(mode_icon(%{type: "using_wheelchair"}), "<svg")
      assert_rendered(mode_icon(%{type: "park_car"}), "<svg")
      assert_rendered(mode_icon(%{type: "bike"}), "<svg")
      assert_rendered(mode_icon(%{type: "CR-Haverhill"}), "<span")
      assert_rendered(mode_icon(%{type: "131"}), "<span")
    end
  end

  defp assert_rendered(result, pattern) do
    assert %Phoenix.LiveView.Rendered{static: static} = result
    assert Enum.any?(static, fn output -> output =~ pattern end)
  end
end
