import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustle_stay/models/chat/chat.dart';
import 'package:hustle_stay/models/chat/message.dart';
import 'package:hustle_stay/models/complaint/complaint.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/providers/state_switch.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/selection_vault.dart';
import 'package:hustle_stay/widgets/other/loading_elevated_button.dart';

// ignore: must_be_immutable
class ComplaintBottomBar extends ConsumerWidget {
  ComplaintData complaint;
  ComplaintBottomBar({
    super.key,
    required this.context,
    required this.complaint,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> buttons = [
      ElevatedButton.icon(
        icon: const Icon(Icons.check_rounded),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () => resolveComplaint(ref),
        label: Text(
          (complaint.from != currentUser.email ? ' Request to ' : '') +
              (complaint.resolvedAt != null ? 'Unresolve' : 'Resolve'),
        ),
      ),
      LoadingElevatedButton(
        icon: const Icon(Icons.person_add_rounded),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: showIncludeBox,
        label: Text(
            '${complaint.from != currentUser.email ? ' Request to ' : ''}Include'),
      ),
    ];
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.separated(
          separatorBuilder: (ctx, index) => const VerticalDivider(),
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx, index) => buttons[index],
          itemCount: buttons.length,
        ),
      ),
    );
  }

  Future<void> showIncludeBox() async {
    List<String> allUsers = [];
    try {
      allUsers = (await fetchComplainees()).map((e) => e.email!).toList();
    } catch (e) {
      showMsg(context, e.toString());
    }
    List<String> chosenUsers = [];
    allUsers.removeWhere((element) => complaint.to.contains(element));
    if (context.mounted) {
      final response = await Navigator.of(context).push<bool?>(DialogRoute(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Complainees'),
              scrollable: true,
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(
                top: 20,
                left: 10,
                right: 10,
              ),
              actionsAlignment: MainAxisAlignment.center,
              content: SelectionVault(
                helpText: "Add a receipient",
                allItems: allUsers.toSet(),
                chosenItems: chosenUsers.toSet(),
                onChange: (newUsers) {
                  chosenUsers = newUsers.toList();
                },
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add'),
                )
              ],
            );
          }));
      if (response == true) {
        if (chosenUsers.isEmpty) {
          if (context.mounted) {
            showMsg(context, "Choose atleast one recepient.");
          }
          return;
        }
        if (complaint.from != currentUser.email) {
          await addMessage(
            ChatData(
              path: "complaints/${complaint.id}",
              owner: complaint.from,
              receivers: complaint.to,
              title: complaint.title,
              description: complaint.description,
            ),
            MessageData(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              txt:
                  "${currentUser.name ?? currentUser.email} requested to include $chosenUsers in the complaint.",
              from: currentUser.email!,
              createdAt: DateTime.now(),
              indicative: true,
            ),
          );
          return;
        }
        complaint.to.addAll(chosenUsers);
        await updateComplaint(complaint);
        await addMessage(
          ChatData(
            path: "complaints/${complaint.id}",
            owner: complaint.from,
            receivers: complaint.to,
            title: complaint.title,
            description: complaint.description,
          ),
          MessageData(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            txt:
                "${currentUser.name ?? currentUser.email} included $chosenUsers in the complaint",
            from: currentUser.email!,
            createdAt: DateTime.now(),
            indicative: true,
          ),
        );
      }
    }
  }

  void resolveComplaint(ref) async {
    if (complaint.from != currentUser.email) {
      await addMessage(
        ChatData(
          path: "complaints/${complaint.id}",
          owner: complaint.from,
          receivers: complaint.to,
          title: complaint.title,
          description: complaint.description,
        ),
        MessageData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          txt:
              "${currentUser.name ?? currentUser.email} requested to ${complaint.resolvedAt != null ? 'unresolve' : 'resolve'} the complaint at\n${ddmmyyyy(DateTime.now())} ${timeFrom(DateTime.now())}",
          from: currentUser.email!,
          createdAt: DateTime.now(),
          indicative: true,
        ),
      );
      return;
    }
    String? response = await askUser(
      context,
      "${complaint.resolvedAt != null ? 'Unresolve' : 'Resolve'} the complaint?",
      description: complaint.resolvedAt != null
          ? "Unresolving the complaint will activate this complaint again."
          : "Do you confirm that the complaint has indeed been resolved from your perspective?",
      yes: true,
      no: true,
    );
    if (response == 'yes') {
      if (complaint.resolvedAt == null) {
        complaint.resolvedAt = DateTime.now().millisecondsSinceEpoch;
      } else {
        complaint.resolvedAt = null;
      }
      updateComplaint(complaint);
      await addMessage(
        ChatData(
          path: "complaints/${complaint.id}",
          owner: complaint.from,
          receivers: complaint.to,
          title: complaint.title,
          description: complaint.description,
        ),
        MessageData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          txt:
              "${currentUser.name ?? currentUser.email} ${complaint.resolvedAt != null ? 'resolved' : 'unresolved'} the complaint at\n${ddmmyyyy(DateTime.now())} ${timeFrom(DateTime.now())}",
          from: currentUser.email!,
          createdAt: DateTime.now(),
          indicative: true,
        ),
      );
      ComplaintsBuilder.complaints
          .removeWhere((element) => element.id == complaint.id);
      toggleSwitch(ref, complaintBuilderSwitch);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
