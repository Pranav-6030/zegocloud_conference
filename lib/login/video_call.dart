import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class VideoCall extends StatefulWidget {
  final String conferenceID;
  final String userID;
  final String userName;
  final String profilePictureUrl;

  const VideoCall({
    Key? key,
    required this.conferenceID,
    required this.userID,
    required this.userName,
    this.profilePictureUrl = "https://www.mockofun.com/wp-content/uploads/2019/12/circle-image.jpg",
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

    // Ensure the microphone starts off and state sync with isMuted
    ZegoUIKit().turnMicrophoneOn(false);
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
    // Check if permission is granted to unmute
    if (!hasUnmutePermission && isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have permission to unmute")),
      );
      return;
    }

    // Toggle the mute status in SDK and update the state
    ZegoUIKit().turnMicrophoneOn(isMuted); // Sync with SDK
    setState(() {
      isMuted = !isMuted;
    });

    print("Mute Toggled: $isMuted");
  }

  void toggleHandRaise() {
    setState(() {
      isHandRaised = !isHandRaised;
    });
    print("Hand raise status: $isHandRaised");
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    print("Like status: $isLiked");
  }

  void toggleUnmutePermission() {
    setState(() {
      hasUnmutePermission = !hasUnmutePermission;
    });

    if (hasUnmutePermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have permission to unmute")),
      );

      countdown = 30;
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

    print("Unmute permission: $hasUnmutePermission");
  }

  void revokePermission() {
    setState(() {
      hasUnmutePermission = false;
      countdown = 0;
      isMuted = true; // Update the icon state to reflect muted status
    });

    // Automatically mute the microphone
    ZegoUIKit().turnMicrophoneOn(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your permission has been revoked, mic muted")),
    );

    print("Permission revoked, mic muted");
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // Stop observing lifecycle
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
                bottomMenuBarConfig: ZegoBottomMenuBarConfig(
                  extendButtons: [
                    FloatingActionButton(
                      onPressed: toggleMute,
                      backgroundColor: Colors.red,
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
              )..avatarBuilder = (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
                  return user != null
                      ? Container(
                          width: size.width,
                          height: size.height,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(widget.profilePictureUrl),
                            ),
                          ),
                        )
                      : const SizedBox();
                },
            ),
            Positioned(
              bottom: 100,
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
              bottom: 100,
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
            if (hasUnmutePermission && countdown > 0) // Show countdown
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
