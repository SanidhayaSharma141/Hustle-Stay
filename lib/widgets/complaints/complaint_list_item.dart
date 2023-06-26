import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustle_stay/models/chat/chat.dart';
import 'package:hustle_stay/models/complaint.dart';
import 'package:hustle_stay/models/message.dart';
import 'package:hustle_stay/models/user.dart';
import 'package:hustle_stay/providers/complaint_list.dart';
import 'package:hustle_stay/screens/chat/chat_screen.dart';
import 'package:hustle_stay/screens/complaints/edit_complaints_page.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/complaints/complaint_bottom_bar.dart';

class ComplaintListItem extends ConsumerStatefulWidget {
  ComplaintListItem({
    super.key,
    required this.complaint,
  });

  ComplaintData complaint;

  @override
  ConsumerState<ComplaintListItem> createState() => _ComplaintListItemState();
}

class _ComplaintListItemState extends ConsumerState<ComplaintListItem> {
  bool _animate = false;

  final duration = const Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showComplaintChat(context, widget.complaint),
      onLongPress: () => _showInfo(),
      title: Text(widget.complaint.title),
      subtitle: widget.complaint.description == null
          ? null
          : Text(
              widget.complaint.description!,
              overflow: TextOverflow.fade,
              maxLines: 4,
            ),
      leading: widget.complaint.imgUrl == null
          ? Icon(
              Icons.info_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            )
          : CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.complaint.imgUrl!),
            ),
    )
        .animate(target: !_animate ? 1 : 0)
        .fade(begin: 0, end: 1, duration: duration);
  }

  void editMe() async {
    final editedComplaint = await navigatorPush(
      context,
      EditComplaintsPage(
        id: widget.complaint.id,
        deleteMe: deleteMe,
      ),
    );
    if (editedComplaint != null) {
      if (editedComplaint == "deleted") {
        ref.read(complaintsList.notifier).removeComplaint(widget.complaint);
      } else {
        setState(() {
          _animate = !_animate;
        });
        Future.delayed(duration, () {
          setState(() {
            widget.complaint = editedComplaint;
            _animate = !_animate;
          });
        });
      }
    }
  }

  Future<void> deleteMe() async {
    final response = await askUser(
      context,
      'Do you really wish to delete this complaint?',
      yes: true,
      no: true,
    );
    if (response == 'yes') {
      await deleteComplaint(complaint: widget.complaint);
    }
  }

  void _showInfo() {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(int.parse(widget.complaint.id));
    Navigator.of(context).push(
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            scrollable: true,
            actionsPadding: const EdgeInsets.only(bottom: 15),
            contentPadding: const EdgeInsets.only(top: 15, left: 20, right: 20),
            actionsAlignment: MainAxisAlignment.spaceAround,
            title: Text(widget.complaint.title),
            actions: [
              IconButton(
                onPressed: () => showComplaintChat(context, widget.complaint),
                icon: const Icon(Icons.chat_rounded),
              ),
              IconButton(
                onPressed: editMe,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: deleteMe,
                icon: const Icon(Icons.delete_rounded),
              ),
            ],
            content: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.complaint.description != null &&
                    widget.complaint.description!.isNotEmpty)
                  Text(
                    "Description: ",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                if (widget.complaint.description != null &&
                    widget.complaint.description!.isNotEmpty)
                  Text(widget.complaint.description!),
                Text(
                  "Complainant: ",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  widget.complaint.from,
                  textAlign: TextAlign.right,
                ),
                Text(
                  "Complainees: ",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text("${widget.complaint.to}"),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Created At: ",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      "${createdAt.day}-${createdAt.month}-${createdAt.year}",
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Creates and Navigates you to the approriate Chat Screen based on the complaint
Future<void> showComplaintChat(BuildContext context, ComplaintData complaint,
    {MessageData? initialMsg}) {
  return navigatorPush<void>(
    context,
    ChatScreen(
      initialMsg: initialMsg,
      bottomBar: ComplaintBottomBar(
        context: context,
        complaint: complaint,
      ),
      chat: ChatData(
        path: "complaints/${complaint.id}",
        owner: UserData(email: complaint.from),
        receivers: complaint.to.map((e) => UserData(email: e)).toList(),
        title: complaint.title,
        description: complaint.description,
      ),
    ),
  );
}
