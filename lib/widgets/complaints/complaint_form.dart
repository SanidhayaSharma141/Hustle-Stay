import 'package:flutter/material.dart';
import 'package:hustle_stay/models/category/category.dart';
import 'package:hustle_stay/models/chat/chat.dart';
import 'package:hustle_stay/models/chat/message.dart';
import 'package:hustle_stay/models/complaint/complaint.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/select_one.dart';
import 'package:hustle_stay/widgets/other/selection_vault.dart';
import 'package:hustle_stay/widgets/requests/grid_tile_logo.dart';

class ComplaintForm extends StatefulWidget {
  final ComplaintData? complaint;
  final Category? category;
  final Future<void> Function(ComplaintData complaint)? afterSubmit;
  final Future<void> Function()? deleteMe;
  const ComplaintForm({
    super.key,
    this.complaint,
    this.category,
    this.deleteMe,
    this.afterSubmit,
  });

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  bool _loading = false;
  late ComplaintData complaint;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      complaint =
          ComplaintData.load(widget.complaint!.id, widget.complaint!.encode());
    } else {
      complaint = ComplaintData(
        from: currentUser.email!,
        id: 0,
        to: [],
        category: widget.category != null ? widget.category!.id : 'Other',
        scope: Scope.private,
      );
    }
  }

  Future<void> _save() async {
    if (complaint.description == null ||
        complaint.description!.trim().isEmpty) {
      showMsg(context, 'Please enter the description');
      return;
    }
    if (complaint.category == 'Other' && complaint.to.isEmpty) {
      showMsg(context, 'Add Some Complainants First');
      return;
    }
    complaint.description = complaint.description!.trim();
    bool isNew = widget.complaint == null;
    // if (isNew) complaint.id = DateTime.now().millisecondsSinceEpoch;
    if (complaint.category != 'Other') complaint.to.clear();
    setState(() {
      _loading = true;
    });
    try {
      complaint = await updateComplaint(complaint);
    } catch (e) {
      showMsg(context, e.toString());
      if (context.mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    if (context.mounted) {
      setState(() {
        _loading = false;
      });
    }
    if (context.mounted) {
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(complaint);
      }
    }
    if (!isNew) {
      String difference = widget.complaint! - complaint;
      if (difference.isNotEmpty) {
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
                "${currentUser.name ?? currentUser.email} changed the$difference",
            from: currentUser.email!,
            createdAt: DateTime.now(),
            indicative: true,
          ),
        );
      }
    } else {
      /// TODO: These lines of code allow us to navigate to the chat screen with a template message for the complaint
      // if (context.mounted) {
      //   await showComplaintChat(
      //     context,
      //     complaint,
      //     initialMsg: MessageData(
      //       id: DateTime.now().millisecondsSinceEpoch.toString(),
      //       from: currentUser.email!,
      //       createdAt: DateTime.now(),
      //       txt: complaintTemplateMessage(complaint),
      //     ),
      //   );
      // }
    }
    if (widget.afterSubmit != null) {
      widget.afterSubmit!(complaint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.deleteMe != null)
            IconButton(
              onPressed: widget.deleteMe,
              icon: const Icon(Icons.delete_rounded),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Category Title
              CategoryBuilder(
                loadingWidget: GridTileLogo(
                  title: complaint.category ?? 'Other',
                  icon: Icon(
                    widget.category != null
                        ? widget.category!.icon
                        : Icons.category_rounded,
                    size: 50,
                  ),
                  color: Theme.of(context).colorScheme.background,
                ),
                id: complaint.category ?? 'Other',
                builder: (ctx, category) => GridTileLogo(
                  onTap: () => Navigator.of(context).pop(),
                  title: category.id,
                  icon: Icon(category.icon, size: 50),
                  color: Theme.of(context).colorScheme.background,
                ),
              ),

              // Choose Category
              if (complaint.id != 0) const SizedBox(height: 30),
              if (widget.complaint != null && widget.complaint!.id != 0)
                CategoriesBuilder(
                  builder: (ctx, categories) => SelectOne(
                    title: 'Change Category',
                    selectedOption: complaint.category ?? 'Other',
                    allOptions: categories.map((e) => e.id).toSet(),
                    onChange: (value) {
                      setState(() {
                        complaint.category = value;
                      });
                      return true;
                    },
                  ),
                ),

              /// Description of Complaint
              const SizedBox(height: 50),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    complaint.description = value.trim();
                  });
                },
                initialValue: complaint.description,
                decoration: InputDecoration(
                  hintText: 'Describe your complaint here',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
              ),

              /// Scope
              const SizedBox(height: 30),
              SelectOne(
                title: 'Visibility',
                subtitle: complaint.scope.index == 0
                    ? 'Visible to everyone'
                    : 'Visible only to you and your complainees',
                allOptions: Scope.values.map((e) => e.name).toSet(),
                selectedOption: complaint.scope.name,
                onChange: (value) {
                  setState(() {
                    complaint.scope = Scope.values
                        .firstWhere((element) => element.name == value);
                  });
                  return true;
                },
              ),

              /// Complainee Chooser
              if (complaint.category == 'Other' || complaint.category == null)
                const SizedBox(height: 30),
              if (complaint.category == 'Other' || complaint.category == null)
                UsersBuilder(
                  builder: (ctx, users) => SelectionVault(
                    allItems: users.map((e) => e.email!).toSet(),
                    onChange: (users) {
                      setState(() {
                        complaint.to = users.toList();
                      });
                    },
                    helpText: 'Choose Complainants',
                    chosenItems: complaint.to.toSet(),
                  ),
                  provider: fetchComplainees,
                ),

              /// Save Button
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _loading ||
                        complaint.description == null ||
                        complaint.description!.isEmpty
                    ? null
                    : _save,
                icon: _loading
                    ? circularProgressIndicator()
                    : const Icon(Icons.report_rounded),
                label: const Text('Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
