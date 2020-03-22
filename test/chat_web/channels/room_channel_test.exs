defmodule ChatWeb.RoomChannelTest do
  use ChatWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(ChatWeb.UserSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(ChatWeb.RoomChannel, "room:lobby")

    {:ok, socket: socket}
  end

  test "shout peer-message to room:lobby", %{socket: socket} do
    push socket, "peer-message", %{"body" => "hello"}
    assert_broadcast "peer-message", %{body: "hello"}
  end
end
