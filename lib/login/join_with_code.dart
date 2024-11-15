import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main_model/login/video_call.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';

class Joinwithcode extends StatelessWidget {
  Joinwithcode({super.key});
  final _controller = TextEditingController();
  final pb = PocketBase('https://api.arcsaep.site/');

  Future<void> _joinMeeting(BuildContext context) async {
    final meetingCode = _controller.text.trim();
    
    try {
      final result = await pb.collection('pranavsMeet').getFirstListItem(
        'meetingCode = "$meetingCode"'
      );

      if (result != null) {
        final timeCounter = result.getIntValue('timeCounter'); // Default to 40 if null
        Get.to(VideoCall(
          conferenceID: meetingCode,
          userID: const Uuid().v4(),         // Replace with the actual user ID
          userName: 'Panama',                // User name from PocketBase
          profilePictureUrl: 'https://www.example.com/profile_picture.jpg',
          countdown: timeCounter,
        ));
      }
    } catch (e) {
      // Show an error if meeting code is not found
      Get.snackbar(
        "Invalid Code",
        "No meeting found with the provided code",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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
                onTap: Get.back,
                child: const Icon(Icons.arrow_back_ios_new_sharp, size: 35),
              ),
            ),
            const SizedBox(height: 10),
            Image.network(
              "https://t4.ftcdn.net/jpg/00/97/58/97/360_F_97589769_t45CqXyzjz0KXwoBZT9PRaWGHRk5hQqQ.jpg",
              fit: BoxFit.cover,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              "Enter meeting code below",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                color: Colors.grey[350],
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Example: abc-efg-dhi",
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: ElevatedButton(
                onPressed: () => _joinMeeting(context),
                child: const Text(
                  "Join",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  fixedSize: const Size(100, 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
