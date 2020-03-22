defmodule ChatWeb.RoomChannel do
  use ChatWeb, :channel
  alias ChatWeb.Presence

  @type topic :: binary
  @type event :: binary
  @type socket :: Phoenix.Socket.t()

  @impl true
  @spec join(topic, map, socket) :: {:ok, socket}
  def join("room:lobby", _payload, socket) do
    send(self(), :after_join)
    uuid = UUID.uuid4()
    response = %{
      uuid: uuid
    }
    {:ok, response, assign(socket, :uuid, uuid)}
  end

  @impl true
  @spec handle_in(event, map, socket) :: {:noreply, socket}
  def handle_in("peer-message", %{"body" => body}, socket) do
    broadcast_from!(socket, "peer-message", %{body: body})
    {:noreply, socket}
  end

  @impl true
  @spec handle_info(any, socket) :: {:noreply, socket}
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      uuid: socket.assigns.uuid,
      online_at: inspect(System.system_time(:second))
    })
    {:noreply, socket}
  end
end
