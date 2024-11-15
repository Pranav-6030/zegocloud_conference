import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class VideoCall extends StatefulWidget {
  final String conferenceID;
  final String userID;
  final String userName;
  final String profilePictureUrl;
  final int countdown;

  const VideoCall({
    Key? key,
    required this.conferenceID,
    required this.userID,
    required this.userName,// 
    this.profilePictureUrl = "https://www.mockofun.com/wp-content/uploads/2019/12/circle-image.jpg",
    required this.countdown,
  }) : super(key: key);

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  bool isMuted = true; // Start muted
  bool hasUnmutePermission = false;
  bool isHandRaised = false;
  bool isLiked = false;
  int countdown = 0; // Countdown in seconds
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle changes
    ZegoUIKit().turnMicrophoneOn(false); // Ensure the microphone starts off
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      leaveCall();
    }
  }

  void leaveCall() {
    ZegoUIKit().leaveRoom(); // Leave the ZEGOCLOUD video call room
    Navigator.of(context).pop();
  }

  void toggleMute() {
    if (hasUnmutePermission) {
      ZegoUIKit().turnMicrophoneOn(!isMuted); // Sync with SDK
      setState(() {
        isMuted = !isMuted;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have no permission to unmute.")),
      );
    }
  }


  void toggleHandRaise() {
    setState(() {
      isHandRaised = !isHandRaised;
    });
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  void toggleUnmutePermission() {
    setState(() {
      hasUnmutePermission = !hasUnmutePermission;
      isMuted = !hasUnmutePermission; // Automatically mute when permission is removed
      ZegoUIKit().turnMicrophoneOn(hasUnmutePermission); // Sync mic state with permission
    });

    if (hasUnmutePermission) {
      countdown = widget.countdown;
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          countdown--;
        });
        if (countdown <= 0) {
          revokePermission();
          countdownTimer?.cancel();
        }
      });
    } else {
      revokePermission();
    }
  }

  void revokePermission() {
    setState(() {
      hasUnmutePermission = false;
      countdown = 0;
      isMuted = true;
    });
    ZegoUIKit().turnMicrophoneOn(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your permission has been revoked, mic muted")),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          ZegoUIKitPrebuiltVideoConference(
            appID: 663528201,
            appSign: "3c9aa57029ff430edff037c3e553668b69e7442dde6d6f2a92c6b2152ea300fe",
            userID: widget.userID,
            userName: widget.userName,
            conferenceID: widget.conferenceID,
            config: ZegoUIKitPrebuiltVideoConferenceConfig(
              turnOnMicrophoneWhenJoining: false,
              avatarBuilder: (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
          return user != null
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        widget.profilePictureUrl,
                      ),
                    ),
                  ),
                )
              : const SizedBox();
        },
              bottomMenuBarConfig: ZegoBottomMenuBarConfig(
                extendButtons: [
                  FloatingActionButton(
                    onPressed: toggleMute,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)
                            ),
                    child: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ],
                buttons: [
                  ZegoMenuBarButtonName.toggleCameraButton,
                  ZegoMenuBarButtonName.switchAudioOutputButton,
                  ZegoMenuBarButtonName.leaveButton,
                  ZegoMenuBarButtonName.switchCameraButton,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 130,
            right: 15,
            child: FloatingActionButton.small(
              onPressed: toggleHandRaise,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.pan_tool,
                color: isHandRaised ? Colors.yellow : Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 130,
            left: 15,
            child: FloatingActionButton.small(
              onPressed: toggleLike,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.thumb_up,
                color: isLiked ? Colors.yellow : Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 300,
            left: 15,
            child: FloatingActionButton.small(
              onPressed: toggleUnmutePermission,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.perm_camera_mic,
                color: hasUnmutePermission ? Colors.yellow : Colors.white,
              ),
            ),
          ),
          if (hasUnmutePermission && countdown > 0)
            Positioned(
              bottom: 350,
              left: 15,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Permission ends in $countdown s",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}