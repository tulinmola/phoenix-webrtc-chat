iceServers = [
  {urls: "stun:stun.l.google.com:19302"}
]

class Peer
  constructor: (@room, @uuid) ->
    configuration = {iceServers}
    @conn = new RTCPeerConnection(configuration)

    {localStream} = @room
    @conn.addTrack(track, localStream) for track in localStream.getTracks()

    @conn.addEventListener("track", @onTrack)
    @conn.addEventListener("icecandidate", @onIceCandidate)
    @conn.addEventListener("connectionstatechange", @onConnection)

    @stream = new MediaStream()
    @createVideoElement()

  createVideoElement: ->
    @element = document.createElement("div")
    @element.className = "video"
    @element.setAttribute("data-user-video-uuid", @uuid)
    @element.innerHTML = """
      <label>#{@uuid}</label>
      <video autoplay></video>
      """

    videos = document.getElementById("videos")
    videos.appendChild(@element)

  createOffer: ->
    console.log("Peer.createOffer", @uuid)
    # options =
    #   offerToReceiveAudio: false
    #   offerToReceiveVideo: false
    @conn.createOffer().then (offer) =>
      @setLocalDescription(offer)
      @room.sendPeerMessage(this, {offer})

  createAnswer: (offer) ->
    console.log("Peer.createAnswer", @uuid, offer)
    @conn.setRemoteDescription(new RTCSessionDescription(offer))
    @conn.createAnswer().then (answer) =>
      @setLocalDescription(answer)
      @room.sendPeerMessage(this, {answer})

  setLocalDescription: (offer) ->
    console.log "Peer.setLocalDescription", offer
    @conn.setLocalDescription(offer)
      .catch (error) ->
        console.error("Peer.setLocalDescription", error)

  setRemoteDescription: (description) ->
    console.log "Peer.setRemoteDescription", description
    @conn.setRemoteDescription(description)
      .catch (error) -> console.error("Peer.setRemoteDescription", error)

  addIceCandidate: (candidate) ->
    console.log "Peer.addIceCandidate", candidate
    @conn.addIceCandidate(candidate)
      .catch (error) -> console.error("Peer.addIceCandidate", error)

  disconnect: ->
    console.log "Peer.disconnect"
    @conn.close()
    @element.parentNode.removeChild(@element)

  onTrack: (event) =>
    console.log "Peer.onTrack", event
    @stream.addTrack(event.track)

  onIceCandidate: (event) =>
    console.log "Peer.onIceCandidate", event
    iceCandidate = event.candidate
    @room.sendPeerMessage(this, {iceCandidate}) if iceCandidate

  onConnection: (event) =>
    console.log "Peer.onConnection", event
    if @conn.connectionState == "connected"
      console.log "Peers connected", @room.uuid, this.uuid
      [video] = @element.getElementsByTagName("video")
      video.srcObject = @stream

export default Peer
