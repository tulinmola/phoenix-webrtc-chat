import socket from "./socket"
import {Presence} from "phoenix"

import Peer from "./peer"

class Room
  constructor: (topic, @localStream) ->
    @peers = {}
    @localUuid = window.userUuid
    @channel = socket.channel("room:#{topic}", {})
    @channel.join()
      .receive "ok", @onJoinChannel
      .receive "error", (response) -> console.error("Unable to join", response)
    @channel.on("peer-message", @onPeerMessage)
    @channel.on("presence_state", @onPresenceState)
    @presence = new Presence(@channel)
    @presence.onJoin(@onPeerJoin)
    @presence.onLeave(@onPeerLeave)

  makeCall: (peer) ->
    console.log "Room.makeCall", peer.uuid
    peer.createOffer()
      .catch (error) -> console.log("Room.makeCall", error)

  answer: (peer, offer) ->
    console.log "Room.answer", peer.uuid, offer
    peer.createAnswer(offer)
      .catch (error) -> console.log("Room.answer", error)

  onJoinChannel: (response) =>
    @uuid = response.uuid

  createPeer: (uuid) ->
    peer = new Peer(this, uuid)
    @peers[uuid] = peer
    peer

  destroyPeer: (uuid) ->
    @peers[uuid].disconnect()
    delete @peers[uuid]

  getPeer: (uuid) ->
    @peers[uuid] || @createPeer(uuid)

  ensurePeer: (uuid) ->
    @getPeer(uuid)

  onPeerJoin: (id, current, newPresence) =>
    {uuid} = newPresence.metas[newPresence.metas.length - 1]
    console.log "Room.onPeerJoin", uuid
    isMyself = @uuid == uuid
    return if isMyself

    @ensurePeer(uuid)

  onPeerLeave: (_id, _current, leftPresence) =>
    [{uuid}] = leftPresence.metas
    @destroyPeer(uuid)

  onPeerMessage: (message) =>
    console.log "onPeerMessage", message
    return unless message.to == @uuid

    peer = @getPeer(message.from)
    switch
      when message.offer then @answer(peer, message.offer)
      when message.answer then peer.setRemoteDescription(message.answer)
      when message.iceCandidate then peer.addIceCandidate(message.iceCandidate)
      else
        console.error("Room.onPeerMessage Unhandled message type", message)

  onPresenceState: (presences) =>
    for _id, {metas} of presences
      for {uuid} in metas
        peer = @getPeer(uuid)
        @makeCall(peer)
    undefined

  sendPeerMessage: (peer, message) ->
    message = Object.assign({from: @uuid, to: peer.uuid}, message)
    console.log "sendPeerMessage", message
    @channel.push("peer-message", message)

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

constraints =
  video: true
  audio: true

navigator.mediaDevices.getUserMedia(constraints)
  .then (stream) ->
    video = document.getElementById("local-video")
    video.srcObject = stream
    new Room("lobby", stream)
  .catch (error) ->
    console.error("Error accessing media devices.", error)
