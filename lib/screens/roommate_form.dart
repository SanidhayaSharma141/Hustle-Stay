import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import '../tools.dart';

class RoommateForm extends ConsumerStatefulWidget {
  RoommateForm(
      {super.key,
      required this.capacity,
      required this.hostelName,
      required this.roomName,
      required this.numRoommates});
  String roomName;
  String hostelName;
  int capacity;
  int numRoommates;

  @override
  ConsumerState<RoommateForm> createState() => _RoommateFormState();
}

class _RoommateFormState extends ConsumerState<RoommateForm> {
  List<GlobalKey<FormState>> _formKeyList = [];
  final storage = FirebaseFirestore.instance;
  String capitalizeEachWord(String value) {
    List<String> subValue = value.split(' ');
    for (int i = 0; i < subValue.length; i++) {
      String word = subValue[i];
      if (word.isNotEmpty) {
        subValue[i] = word[0].toUpperCase() + word.substring(1);
      }
    }
    return subValue.join(' ');
  }

  int currentRoommateNumber = 0;
  String roommateName = "";
  String roommateEmail = "";
  String roommateRollNum = "";
  bool isOverflow = false;
  var numOfRoommates = 0;
  bool isRunning = false;
  void addRoommate(int index) async {
    if (_formKeyList[index].currentState!.validate()) {
      _formKeyList[index].currentState!.save();
      try {
        final loc = storage
            .collection('hostels')
            .doc(widget.hostelName)
            .collection('Rooms')
            .doc(widget.roomName);

        await loc.collection('Roommates').doc(roommateEmail).set({
          'name': roommateName,
          'email': roommateEmail,
          "rollNumber": roommateRollNum,
        });
        await loc.update({'numRoommates': FieldValue.increment(1)});
        if (currentRoommateNumber < numOfRoommates - 1) {
          setState(() {
            currentRoommateNumber += 1;
            roommateName = "";
            roommateEmail = "";
            roommateRollNum = "";
            isRunning = false;
          });
          return;
        }
        Navigator.of(context).pop();
      } catch (e) {
        print(e);
      }
    }
    setState(() {
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: shaderText(context, title: "Add Roommate"),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topLeft,
          child: Column(
            children: [
              // Text("hi"),
              TextField(
                decoration: InputDecoration(
                  label: Text("Number of Roommates to be added"),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    numOfRoommates = int.parse(value);

                    if (!(widget.capacity >=
                        int.parse(value) + widget.numRoommates)) {
                      numOfRoommates = widget.capacity - widget.numRoommates;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Capacity Overflow. Only ${widget.capacity - widget.numRoommates} rooms can be added.")));
                    }
                    for (int i = 0; i < numOfRoommates; i++) {
                      _formKeyList.add(GlobalKey<FormState>());
                    }
                  });
                },
              ),

              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Card(
                      child: Column(
                    children: [
                      Text(
                        "Roommate ${index + 1}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Form(
                        key: _formKeyList[index],
                        child: Column(children: [
                          TextFormField(
                            enabled: index == currentRoommateNumber,
                            decoration: InputDecoration(
                              labelText: "Enter Roommate name",
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Name cannot be empty";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              roommateName = capitalizeEachWord(value);
                            },
                          ),
                          TextFormField(
                            enabled: currentRoommateNumber == index,
                            decoration: InputDecoration(
                              labelText: "Email ID",
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Name cannot be empty";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              roommateEmail = value.toLowerCase();
                            },
                          ),
                          TextFormField(
                            enabled: currentRoommateNumber == index,
                            decoration: InputDecoration(
                              labelText: "Roll No.",
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Roll Number cannot be empty";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              roommateRollNum = value.toUpperCase();
                            },
                          ),
                          if (currentRoommateNumber == index)
                            isRunning
                                ? CircularProgressIndicator()
                                : TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isRunning = true;
                                      });
                                      addRoommate(index);
                                    },
                                    icon: Icon(Icons.add_circle_outline),
                                    label: Text("Add Roommate"))
                        ]),
                      )
                    ],
                  ));
                },
                itemCount:
                    widget.capacity > numOfRoommates + widget.numRoommates
                        ? numOfRoommates
                        : widget.capacity - widget.numRoommates,
                shrinkWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
