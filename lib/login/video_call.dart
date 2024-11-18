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
  bool isMuted = true;
  bool hasUnmutePermission = false;
  bool isHandRaised = false;
  bool isLiked = false;
  int countdown = 0;
  Timer? countdownTimer;
  final pocketBase = PocketBase('https://api.arcsaep.site/');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ZegoUIKit().turnMicrophoneOn(false);
    subscribeToHandRaiseTable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      leaveCall();
    }
  }

  void leaveCall() {
    ZegoUIKit().leaveRoom();
    Navigator.of(context).pop();
  }

  void toggleMute() {
    if (hasUnmutePermission) {
      setState(() {
        isMuted = !isMuted;
      });
      ZegoUIKit().turnMicrophoneOn(!isMuted);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have no permission to unmute.")),
      );
    }
  }

  void toggleHandRaise() async {
    setState(() {
      isHandRaised = !isHandRaised;
    });

    if (isHandRaised) {
      await pocketBase.collection('PranavsHandraise').create(body: {
        'userID': widget.userID,
        'userName': widget.userName,
      });
    } else {
      final records = await pocketBase
          .collection('PranavsHandraise')
          .getFullList(filter: 'userID="${widget.userID}"');
      if (records.isNotEmpty) {
        await pocketBase.collection('PranavsHandraise').delete(records.first.id);
      }
    }
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  void toggleUnmutePermission() {
    setState(() {
      hasUnmutePermission = !hasUnmutePermission;
      isMuted = !hasUnmutePermission;
      ZegoUIKit().turnMicrophoneOn(hasUnmutePermission);
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

void revokePermission() async {
  setState(() {
    hasUnmutePermission = false;
    countdown = 0;
    isMuted = true;
  });
  
  ZegoUIKit().turnMicrophoneOn(false);
  
  // Delete the user's hand raise record when the permission is revoked
  final records = await pocketBase
      .collection('PranavsHandraise')
      .getFullList(filter: 'userID="${widget.userID}"');
  
  if (records.isNotEmpty) {
    await pocketBase.collection('PranavsHandraise').delete(records.first.id);
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Your permission has been revoked, mic muted")),
  );
}


  void subscribeToHandRaiseTable() {
    pocketBase.collection('PranavsHandraise').subscribe('*', (event) {
      handleHandRaiseEvent(event.record);
    });
  }

  void handleHandRaiseEvent(RecordModel? record) async {
    final records = await pocketBase.collection('PranavsHandraise').getFullList(sort: 'created');

    if (records.isNotEmpty) {
      final firstUser = records.first;
      final firstUserID = firstUser.data['userID'];

      // If the first user is not the current user and they haven't been granted permission yet, grant permission
      if (!hasUnmutePermission && firstUserID == widget.userID) {
        toggleUnmutePermission();
      } else if (hasUnmutePermission && firstUserID != widget.userID) {
        revokePermission(); // Revoke permission from others if the current user has permission
      }
    }
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
                              image: NetworkImage(widget.profilePictureUrl),
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
