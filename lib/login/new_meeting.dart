import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main_model/login/video_call.dart';
import 'package:share/share.dart';
import 'package:uuid/uuid.dart';

class NewMeeting extends StatefulWidget {
  NewMeeting({super.key});

  @override
  State<NewMeeting> createState() => _NewMeetingState();
}

class _NewMeetingState extends State<NewMeeting> {
  String _meetingCode = "abcdfgw";
  final _controller = TextEditingController();

  @override
  void initState() {
    var uuid = Uuid();
    _meetingCode = uuid.v1().substring(0, 8);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back_ios_new_sharp, size: 35),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Image.network(
                "https://cdn.impossibleimages.ai/wp-content/uploads/2023/04/22220618/hzG267lIBvu26K6pTKVCdPmtp9HVKX1JD08By9XvTWd3DDHbts-1500x1500.jpg",
                fit: BoxFit.cover,
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your meeting is ready",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                color: Colors.grey[350],
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter the time limit to speak",
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                color: Colors.grey[350],
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: SelectableText(
                    _meetingCode,
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                  trailing: const Icon(Icons.copy),
                ),
              ),
            ),
            const Divider(
              thickness: 1,
              height: 40,
              indent: 20,
              endIndent: 20,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share("Meeting code : $_meetingCode");
                },
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                label: const Text(
                  "Share Invite",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  fixedSize: const Size(325, 30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.to(VideoCall(
                    conferenceID: _meetingCode.trim(),
                    userID: const Uuid().v4(),         // Replace with the actual user ID
                    userName: 'Panama',          // user name from pocketbase
                    profilePictureUrl: 'https://www.example.com/profile_picture.jpg',
                    countdown: int.tryParse(_controller.text.trim())?? 30 ));
                },
                icon: const Icon(
                  Icons.video_call,
                  color: Colors.indigo,
                ),
                label: const Text(
                  "Start Call",
                  style: TextStyle(color: Colors.indigo),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                  fixedSize: const Size(325, 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
