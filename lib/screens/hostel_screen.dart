import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hustle_stay/screens/rooms_screen.dart';
// import 'package:hustle_stay/models/hostels.dart';
// import 'package:hustle_stay/screens/addHostel.dart';

import '../models/hostels.dart';
import '../tools.dart';
import 'add_rooms.dart';
// import 'package:hustle_stay/models/user.dart';

final _firebase = FirebaseAuth.instance;

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final store = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder(
        future: fetchHostels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: circularProgressIndicator(
                height: null,
                width: null,
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('No Hostel added yet!'),
            );
          }
          print(snapshot.data);

          return ListView.builder(
            itemBuilder: (context, index) {
              Hostels hostel = snapshot.data![index];
              String? imageUrl = hostel.imageUrl;
              return InkWell(
                onTap: () => {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RoomsScreen(
                            hostelName: hostel.hostelName,
                          )))
                },
                child: Card(
                  elevation: 6,
                  child: Column(
                    children: [
                      Image.network(
                        imageUrl,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            // Image is fully loaded
                            return child;
                          }
                          return Container(
                            width: double.infinity,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return Text('Failed to load image');
                        },
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hostel.hostelName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "${hostel.hostelType} Hostel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "${hostel.numberOfRooms}",
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => AddRoom(
                                            hostelName: hostel.hostelName))),
                                icon: Icon(Icons.add),
                                label: Text("Add Room")),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            itemCount: snapshot.data!.length,
          );
        },
      ),
    );
  }
}