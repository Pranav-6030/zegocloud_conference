import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';
import 'package:pocketbase/pocketbase.dart';

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
    required this.userName,
    this.profilePictureUrl = "https://www.mockofun.com/wp-content/uploads/2019/12/circle-image.jpg",
    required this.countdown,
  }) : super(key: key);

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  final pb = PocketBase('https://api.arcsaep.site/');
  bool isMuted = true; // Start muted
  bool hasUnmutePermission = false;
  bool isHandRaised = false;
  bool isLiked = false;
  int countdown = 0; // Countdown in seconds
  Timer? countdownTimer;
  String? highlightedUserID; // Store the userID of the highlighted user

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle changes
    subscribeToUnmuteUpdates(); // Start Pocketbase real-time listener
    ZegoUIKit().turnMicrophoneOn(false); // Ensure the microphone starts off
  }

  // Real-time listener for unmute permission updates from Pocketbase
  void subscribeToUnmuteUpdates() {
    pb.collection('pranavUserPermissions').subscribe('*', (e) {
      if (e.action == 'update' || e.action == 'create') {
        final userID = e.record?.getStringValue('userID');
        final hasPermission = e.record?.getBoolValue('hasUnmutePermission');

        setState(() {
          // Highlight the user who has the unmute permission
          highlightedUserID = (hasPermission ?? false) ? userID : null;

          // Sync the local user’s permission with the Pocketbase data
          if (userID == widget.userID) {
            hasUnmutePermission = hasPermission ?? false;
          }
        });
      }
    });
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
    if (!hasUnmutePermission && isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have permission to unmute")),
      );
      return;
    }
    ZegoUIKit().turnMicrophoneOn(isMuted); // Sync with SDK
    setState(() {
      isMuted = !isMuted;
    });
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

  // Update the unmute permission in Pocketbase
void toggleUnmutePermission() async {
  setState(() {
    hasUnmutePermission = !hasUnmutePermission;
  });

  // Send the update to Pocketbase (creating/updating the UserPermissions record)
  final data = <String, dynamic>{
    'userID': widget.userID,
    'hasUnmutePermission': hasUnmutePermission,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };

  // try {
    // Use upsert to avoid failure if the record already exists
    final record = await pb.collection('pranavUserPermissions').create(body: data );

    // If permission is granted, start the countdown
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

    print('Unmute permission updated for user: ${widget.userID}');
  // } catch (e) {
  //   print('Error updating unmute permission: $e');
  // }
}


  // Revoke unmute permission
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
    pb.collection('UserPermissions').unsubscribe('*');
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
                  bool isHighlighted = user?.id == highlightedUserID;
                  return user != null
                      ? Container(
                          width: size.width,
                          height: size.height,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isHighlighted ? Border.all(color: Colors.yellow, width: 3) : null,
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
