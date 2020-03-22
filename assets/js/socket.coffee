import {Socket} from "phoenix"

params = user_id: window.user_id
socket = new Socket("/socket", {params})

socket.onOpen (response) ->  console.log("Socket opened", response)
socket.onClose () -> console.warn("Socket closed")
socket.onError (error) -> console.error("Socket error", error)

socket.connect()

export default socket
