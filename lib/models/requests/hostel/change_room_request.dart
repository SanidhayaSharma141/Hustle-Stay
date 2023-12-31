import 'package:flutter/material.dart';
import 'package:hustle_stay/models/hostel/rooms/room.dart';
import 'package:hustle_stay/models/requests/request.dart';
import 'package:hustle_stay/models/user/user.dart';

class ChangeRoomRequest extends Request {
  String targetRoomName;
  String targetHostel;
  ChangeRoomRequest({
    required super.requestingUserEmail,
    this.targetRoomName = '',
    this.targetHostel = '',
  }) : super(
          type: 'Change_Room',
          uiElement: {
            'color': Colors.blueAccent,
            'icon': Icons.transfer_within_a_station_rounded,
          },
        );

  @override
  Map<String, dynamic> encode() {
    return super.encode()
      ..addAll({
        'targetRoomName': targetRoomName,
        'targetHostel': targetHostel,
      });
  }

  @override
  void load(Map<String, dynamic> data) {
    super.load(data);
    targetRoomName = data['targetRoomName']!;
    targetHostel = data['targetHostel']!;
  }

  @override
  bool beforeUpdate() {
    targetRoomName = targetRoomName.trim();
    targetHostel = targetHostel.trim();
    assert(targetRoomName.isNotEmpty);
    assert(targetHostel.isNotEmpty);
    return super.beforeUpdate();
  }

  @override
  Future<void> onApprove(transaction) async {
    print('entered onApprove');

    /// TODO: Sani | make use of this transaction to do things atomically
    /// using it will ensure that approving is done atomically
    final user = await fetchUserData(requestingUserEmail);
    final ref = await changeRoom(requestingUserEmail, user.hostelName!,
        user.roomName!, targetHostel, targetRoomName);
    if (ref) {
      return;
    }
  }

  @override
  Widget widget(context) {
    return super.listWidget(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(children: [
            Text(
              "$targetRoomName - $targetHostel",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 5),
            if (reason.isNotEmpty)
              Text(
                "| $reason",
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ]),
        ],
      ),
      {
        '-': '-',
        'Requested Hostel Name': targetHostel,
        'Requested Room Name': targetRoomName,
      },
    );
  }
}
