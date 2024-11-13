import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class VideoCall extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltVideoConference(
        appID: 663528201, // Your ZEGOCLOUD appID
        appSign: "3c9aa57029ff430edff037c3e553668b69e7442dde6d6f2a92c6b2152ea300fe", // Your ZEGOCLOUD appSign
        userID: userID,
        userName: userName,
        conferenceID: conferenceID,
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
                        image: NetworkImage(profilePictureUrl),
                      ),
                    ),
                  )
                : const SizedBox();
          },
      ),
    );
  }
  }