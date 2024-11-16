import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main_model/login/join_with_code.dart';
import 'package:main_model/login/new_meeting.dart';
import 'package:main_model/login/video_call.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';

class GDinterface extends StatefulWidget {
  const GDinterface({super.key});

  @override
  State<GDinterface> createState() => _GDinterfaceState();
}

class _GDinterfaceState extends State<GDinterface> {
  final PocketBase pb = PocketBase('https://api.arcsaep.site/'); // Replace with your PocketBase URL
  final List<Map<String, dynamic>> _meetingData = []; // To store meeting details

  @override
  void initState() {
    super.initState();
    _fetchMeetings(); // Fetch initial data
    _subscribeToChanges(); // Subscribe to real-time updates
  }

  @override
  void dispose() {
    pb.collection('Pranavsmeetings').unsubscribe('*'); // Unsubscribe when widget is disposed
    super.dispose();
  }

  Future<void> _fetchMeetings() async {
    try {
      final records = await pb.collection('Pranavsmeetings').getFullList();
      setState(() {
        _meetingData.clear();
        _meetingData.addAll(records.map((record) {
          // Parse the times as DateTime objects (UTC by default)
          final startTime = DateTime.parse(record.data['start_time']).toLocal();
          final endTime = DateTime.parse(record.data['end_time']).toLocal();
          
          // Return a map with local time
          return {
            'topic': record.data['topic'],
            'startTime': startTime,
            'endTime': endTime,
            'countdown': record.data['countdown'],
          };
        }));
      });
    } catch (e) {
      print('Error fetching meetings: $e');
    }
  }

  void _subscribeToChanges() {
    pb.collection('Pranavsmeetings').subscribe('*', (event) {
      _fetchMeetings(); // Refresh the meeting list on any change
    });
  }

  Future<void> _displayBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        height: 250,
        width: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 50, 0, 0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(NewMeeting());
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "New Meeting",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  fixedSize: const Size(325, 30),
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
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.to(Joinwithcode());
                },
                icon: const Icon(Icons.margin, color: Colors.indigo),
                label: const Text(
                  "Join with a code",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Group Discussion',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _meetingData.isEmpty
              ? const Center(child: CircularProgressIndicator()) // Show loading indicator if data is empty
              : ListView.builder(
                  itemCount: _meetingData.length,
                  itemBuilder: (context, index) {
                    final meeting = _meetingData[index];
                    final now = DateTime.now();

                    // Debugging output
                    print('Now: $now, Start: ${meeting['startTime']}, End: ${meeting['endTime']}');

                    if (now.isAfter(meeting['endTime'])) {
                      // Remove expired meetings
                      Future.delayed(Duration.zero, () {
                        setState(() {
                          _meetingData.removeAt(index);
                        });
                      });
                      return const SizedBox.shrink(); // Return empty widget for expired meetings
                    } else if (now.isBefore(meeting['startTime'])) {
                      // Meeting is yet to start
                      return _buildScheduledMeeting(meeting);
                    } else if (now.isAfter(meeting['startTime']) && now.isBefore(meeting['endTime'])) {
                      // Meeting is active
                      return _buildMeetingContainer(meeting);
                    }

                    return const SizedBox.shrink(); // Fallback case
                  },
                ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _displayBottomSheet(context);
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledMeeting(Map<String, dynamic> meeting) {
    // No need to convert again since time is already converted during fetch
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 240),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        height: 120,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting['topic'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Starts at: ${meeting['startTime']}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Ends at: ${meeting['endTime']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingContainer(Map<String, dynamic> meeting) {
    // No need to convert again since time is already converted during fetch
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 251, 253, 255),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        height: 160,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting['topic'],
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Started at: ${meeting['startTime']}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Ends at: ${meeting['endTime']}',
                style: const TextStyle(color: Colors.grey),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10), // Adjust right padding to shift left
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(VideoCall(
                        conferenceID: 'test',//get some rubbish from pocketbase this should be common for all the user to join the same meeting
                        userID: const Uuid().v4(),//u can leave this as it is if you want
                        userName: 'Panama', // Replace with actual user data
                        profilePictureUrl: 'https://www.mockofun.com/wp-content/uploads/2019/12/circle-image.jpg',// get profile picture from pocketbase
                        countdown: meeting['countdown'],
                      ));
                    },
                    label: const Text(
                      "Join",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      fixedSize: const Size(110, 40), // Increased width and height
                    ),
                    icon: const Icon(Icons.video_call),
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}


