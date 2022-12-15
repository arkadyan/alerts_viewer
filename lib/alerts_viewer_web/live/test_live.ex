defmodule AlertsViewerWeb.TestLive do
  use AlertsViewerWeb, :live_view

  def mount(_params, _session, socket) do
    items = ["a", "b", "c"]

    socket =
      assign(socket,
        items: items,
        filter: ""
      )

    {:ok, socket, temporary_assigns: [items: []]}
  end

  def render(assigns) do
    ~H"""
    <form phx-change="filter" class="flex">
      <.input
        type="select"
        id="filter"
        name="filter"
        prompt="All"
        value={@filter}
        options={options()}
        errors={[]}
      />
    </form>
    filter = <%= @filter %>
    <ul id="items">
      <li :for={item <- @items} :if={filter(item, @filter)} id={item}>
        <%= item %>
        <br />
        <%= @filter %>
      </li>
    </ul>
    """
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    socket = assign(socket, filter: filter)
    {:noreply, socket}
  end

  def options(), do: [A: "a", B: "b", C: "c"]

  def filter(item, filter) do
    IO.puts("item=#{item}, filter=#{filter}")
    filter == "" or item == filter
  end
end
