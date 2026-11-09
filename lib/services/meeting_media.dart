import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Camera, microphone and peer connections of a meeting (web `WebrtcPeerService`).
/// Offers, answers and ICE candidates go through as the JSON text of the
/// signaling payloads, in the format of the browsers' `JSON.stringify`.
abstract class MeetingMedia {
  /// A local ICE candidate to send to a peer.
  void Function(String peerId, String candidate)? onCandidate;

  /// The video of a peer or the local one is available: the UI must refresh.
  void Function()? onStreamsChanged;

  /// Opens the camera and microphone, or the microphone only. Returns `false`
  /// when neither is available: the user then only receives.
  Future<bool> openLocal();

  /// Renderer of a peer, or the local one when [peerId] is null.
  RTCVideoRenderer? renderer(String? peerId);

  bool get hasCamera;

  /// Whether this peer has an offer of ours still unanswered.
  Future<bool> hasPendingOffer(String peerId);

  Future<String> createOffer(String peerId);
  Future<String> acceptOffer(String peerId, String offer);
  Future<void> acceptAnswer(String peerId, String answer);
  Future<void> addCandidate(String peerId, String candidate);
  Future<void> closePeer(String peerId);

  void setMuted(bool muted);
  void setVideoOff(bool off);
  Future<void> switchCamera();

  Future<void> dispose();
}

class WebRtcMeetingMedia extends MeetingMedia {
  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  final Map<String, _Peer> _peers = {};
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  bool _disposed = false;

  @override
  Future<bool> openLocal() async {
    _localStream = await _userMedia(video: true) ?? await _userMedia(video: false);
    final stream = _localStream;
    if (stream == null) return false;
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {
      // Keeps the current audio route.
    }
    if (stream.getVideoTracks().isNotEmpty) {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = stream;
      _localRenderer = renderer;
    }
    return true;
  }

  static Future<MediaStream?> _userMedia({required bool video}) async {
    try {
      return await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user'} : false,
      });
    } catch (_) {
      return null;
    }
  }

  @override
  RTCVideoRenderer? renderer(String? peerId) => peerId == null ? _localRenderer : _peers[peerId]?.renderer;

  @override
  bool get hasCamera => _localStream?.getVideoTracks().isNotEmpty ?? false;

  /// Negotiations are never reused: a new offer always means a new connection
  /// (the peer came back after a network loss, the web does not renegotiate).
  Future<_Peer> _newPeer(String peerId) async {
    await closePeer(peerId);
    final connection = await createPeerConnection(_config);
    final peer = _Peer(connection);
    _peers[peerId] = peer;
    connection.onIceCandidate = (candidate) {
      if (candidate.candidate != null) onCandidate?.call(peerId, jsonEncode(candidate.toMap()));
    };
    connection.onTrack = (event) => _attachStream(peerId, peer, event);
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await connection.addTrack(track, stream);
      }
    }
    return peer;
  }

  Future<void> _attachStream(String peerId, _Peer peer, RTCTrackEvent event) async {
    if (event.streams.isEmpty) return;
    final renderer = peer.renderer ?? RTCVideoRenderer();
    if (peer.renderer == null) {
      await renderer.initialize();
      if (_peers[peerId] != peer) {
        await renderer.dispose();
        return;
      }
      peer.renderer = renderer;
    }
    renderer.srcObject = event.streams.first;
    onStreamsChanged?.call();
  }

  @override
  Future<bool> hasPendingOffer(String peerId) async {
    final state = _peers[peerId]?.connection.signalingState;
    return state == RTCSignalingState.RTCSignalingStateHaveLocalOffer;
  }

  @override
  Future<String> createOffer(String peerId) async {
    final peer = await _newPeer(peerId);
    if (_localStream == null) {
      // Without any track, the offer would not ask for the peer's media.
      for (final kind in const [RTCRtpMediaType.RTCRtpMediaTypeAudio, RTCRtpMediaType.RTCRtpMediaTypeVideo]) {
        await peer.connection.addTransceiver(
          kind: kind,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      }
    }
    final offer = await peer.connection.createOffer();
    await peer.connection.setLocalDescription(offer);
    return jsonEncode(offer.toMap());
  }

  @override
  Future<String> acceptOffer(String peerId, String offer) async {
    final peer = await _newPeer(peerId);
    await peer.setRemote(_description(offer));
    final answer = await peer.connection.createAnswer();
    await peer.connection.setLocalDescription(answer);
    return jsonEncode(answer.toMap());
  }

  @override
  Future<void> acceptAnswer(String peerId, String answer) async {
    if (await hasPendingOffer(peerId)) await _peers[peerId]!.setRemote(_description(answer));
  }

  @override
  Future<void> addCandidate(String peerId, String candidate) async {
    final json = jsonDecode(candidate) as Map<String, dynamic>;
    await _peers[peerId]?.addCandidate(
      RTCIceCandidate(json['candidate'] as String?, json['sdpMid'] as String?, (json['sdpMLineIndex'] as num?)?.toInt()),
    );
  }

  static RTCSessionDescription _description(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return RTCSessionDescription(map['sdp'] as String?, map['type'] as String?);
  }

  @override
  Future<void> closePeer(String peerId) async {
    final peer = _peers.remove(peerId);
    if (peer == null) return;
    await peer.close();
    if (!_disposed) onStreamsChanged?.call();
  }

  @override
  void setMuted(bool muted) {
    for (final track in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  @override
  void setVideoOff(bool off) {
    for (final track in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !off;
    }
  }

  @override
  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final id in _peers.keys.toList()) {
      await closePeer(id);
    }
    final renderer = _localRenderer;
    _localRenderer = null;
    if (renderer != null) {
      renderer.srcObject = null;
      await renderer.dispose();
    }
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
  }
}

class _Peer {
  _Peer(this.connection);

  final RTCPeerConnection connection;
  final List<RTCIceCandidate> _pending = [];
  bool _hasRemote = false;
  RTCVideoRenderer? renderer;

  /// Candidates can arrive before the description they belong to: the answering
  /// side starts gathering before its answer is sent.
  Future<void> setRemote(RTCSessionDescription description) async {
    await connection.setRemoteDescription(description);
    _hasRemote = true;
    for (final candidate in _pending) {
      await connection.addCandidate(candidate);
    }
    _pending.clear();
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    if (_hasRemote) {
      await connection.addCandidate(candidate);
    } else {
      _pending.add(candidate);
    }
  }

  Future<void> close() async {
    final view = renderer;
    renderer = null;
    if (view != null) {
      view.srcObject = null;
      await view.dispose();
    }
    await connection.close();
  }
}
