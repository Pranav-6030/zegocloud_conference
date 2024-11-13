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

class _VideoCallState extends State<VideoCall> {
  bool isMuted = true;
  bool hasUnmutePermission = false;
  bool isHandRaised = false;
  bool isLiked = false;
  int countdown = 0; // Countdown in seconds
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    // Start the call muted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toggleMute(true);
    });
  }

void toggleMute(bool mute) {
  ZegoUIKit().turnMicrophoneOn(!mute); // true to unmute, false to mute
  setState(() {
    isMuted = mute;
  });
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
      // Start the countdown at 30 seconds
      countdown = 30;

      // Start a periodic timer to update countdown every second
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          countdown--;
        });

        if (countdown <= 0) {
          // Revoke permission and stop the timer
          revokePermission();
          countdownTimer?.cancel();
        }
      });
    } else {
      // Manually revoke permission and stop the timer
      revokePermission();
    }

    print("Unmute permission: $hasUnmutePermission");
  }

  void revokePermission() {
    setState(() {
      hasUnmutePermission = false;
      countdown = 0; // Reset countdown to hide it
    });

    if (!isMuted) {
      toggleMute(true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Permission revoked, mic muted")),
    );

    print("Permission revoked, mic muted");
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
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
              config: ZegoUIKitPrebuiltVideoConferenceConfig()
                ..avatarBuilder = (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
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
            if (hasUnmutePermission)
              Positioned(
                bottom: 350,
                left: 20,
                child: Text(
                  "Time left: $countdown s",
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}