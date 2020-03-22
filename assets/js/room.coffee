import socket from "./socket"
import {Presence} from "phoenix"

constraints =
  video: true
  audio: true

videos = document.getElementById("videos")

audioInputs = document.getElementById("audio-input")
audioOutputs = document.getElementById("audio-output")
videoInputs = document.getElementById("video-input")

devicesReducer = (acc, device) ->
  {kind: type, deviceId, label} = device
  acc[type] = [] unless acc[type]
  option = "<option value='#{deviceId}'>#{label}</option>"
  acc[type].push(option)
  acc

updateAvailableDevices = ->
  # TODO this only shows current connected devices. They cannot
  # be actually selected nor changed…
  navigator.mediaDevices.enumerateDevices()
    .then (devices) ->
      options = devices.reduce(devicesReducer, {})
      audioInputs.innerHTML = options["audioinput"].join("")
      audioOutputs.innerHTML = options["audiooutput"].join("")
      videoInputs.innerHTML = options["videoinput"].join("")

updateAvailableDevices()
navigator.mediaDevices.addEventListener("devicechange", updateAvailableDevices)

# localVideo = document.getElementById("local-video")

# navigator.mediaDevices.getUserMedia(constraints)
#   .then (stream) ->
#     localVideo.srcObject = stream
#   .catch (error) ->
#     console.error("Error accessing media devices.", error)

onJoinRoom = (response) ->
  window.userUid = response.uuid

channel = socket.channel("room:lobby", {})
channel
  .join()
  .receive "ok", onJoinRoom
  .receive "error", (response) -> console.error("Unable to join", response)

presence = new Presence(channel)

renderOnlineUsers = ->
  users = []
  presence.list (id, {metas: [first, ...rest]}) ->
    count = rest.length + 1
    users.push("<li>#{id} count: #{count}</li>")
  document.getElementById("users").innerHTML = users.join("")

onPresenceJoin = (id, _current, newPresence) ->
  {uuid} = newPresence.metas[newPresence.metas.length - 1]
  return if uuid == window.userUid

  video = document.createElement("div")
  video.className = "video"
  video.setAttribute("data-user-video-uuid", uuid)
  video.innerHTML = """
    <label>#{id}</label>
    <video autoplay></video>
    """

  videos.appendChild(video)

onPresenceLeave = (_id, _current, leftPresence) ->
  [{uuid}] = leftPresence.metas
  element = document.querySelector("[data-user-video-uuid=\"#{uuid}\"]")
  element?.parentNode.removeChild(element)

presence.onSync(renderOnlineUsers)
presence.onJoin(onPresenceJoin)
presence.onLeave(onPresenceLeave)
