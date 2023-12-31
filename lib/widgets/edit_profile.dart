import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hustle_stay/models/user/medical_info.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/providers/image.dart';
import 'package:hustle_stay/screens/admin_panel/permission.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/loading_elevated_button.dart';
import 'package:hustle_stay/widgets/profile_image.dart';
import 'package:hustle_stay/widgets/settings/section.dart';

class EditProfileWidget extends StatefulWidget {
  EditProfileWidget({super.key, UserData? user}) {
    this.user = user ?? UserData();
  }

  late UserData user;
  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _formKey = GlobalKey<FormState>();

  File? img;

  Future<void> save(context) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.user.imgUrl = img != null
        ? await uploadImage(
            context, img, widget.user.email!, "profile-image.jpg")
        : widget.user.imgUrl;
    widget.user.name = widget.user.name == null
        ? null
        : widget.user.name!.trim().toPascalCase();
    await updateUserData(widget.user);
    Navigator.of(context).pop(true); // to show that a change was done
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Hero(
                tag: 'profile-image',
                child: ProfileImage(
                  url: widget.user.imgUrl,
                  onChanged: (value) {
                    img = value;
                  },
                ),
              ),
              Text(
                widget.user.email ?? "",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Divider(),
              Section(title: 'Personal Information', children: [
                if (widget.user.email == null)
                  TextFormField(
                    maxLength: 50,
                    keyboardType: TextInputType.emailAddress,
                    enabled: widget.user.email == null,
                    decoration: const InputDecoration(
                      label: Text("Email"),
                    ),
                    initialValue: widget.user.name,
                    validator: (email) {
                      return Validate.email(email);
                    },
                    onSaved: (email) {
                      widget.user.email = email!.trim();
                    },
                  ),
                TextFormField(
                  maxLength: 50,
                  enabled: widget.user.email == null || currentUser.isAdmin,
                  decoration: const InputDecoration(
                    label: Text("Name"),
                  ),
                  initialValue: widget.user.name,
                  validator: (name) {
                    return Validate.name(name);
                  },
                  onSaved: (value) {
                    widget.user.name = value!.trim();
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    label: Text("Phone Number"),
                  ),
                  initialValue: widget.user.phoneNumber,
                  validator: (name) {
                    return Validate.phone(name, required: false);
                  },
                  onSaved: (value) {
                    widget.user.phoneNumber = value!.trim();
                  },
                ),
                TextFormField(
                  maxLength: 200,
                  keyboardType: TextInputType.streetAddress,
                  decoration: const InputDecoration(
                    label: Text("Address"),
                  ),
                  initialValue: widget.user.address,
                  validator: (name) {
                    return Validate.text(name, required: false);
                  },
                  onSaved: (value) {
                    widget.user.address = value!.trim();
                  },
                ),
                if (currentUser.isAdmin)
                  DropdownButtonFormField(
                      decoration: const InputDecoration(label: Text('Type')),
                      value: widget.user.type,
                      items: ['attender', 'warden', 'student', 'other', "club"]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        widget.user.type = value ?? "student";
                      }),
                if (widget.user.email != currentUser.email &&
                    currentUser.isAdmin)
                  DropdownButtonFormField(
                      decoration: const InputDecoration(label: Text('Admin')),
                      value: widget.user.isAdmin,
                      items: [true, false]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        widget.user.isAdmin = value ?? false;
                      }),
              ]),
              Section(title: 'Medical Information', children: [
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    label: Text("Emergency Phone Number"),
                  ),
                  initialValue: widget.user.medicalInfo.phoneNumber,
                  validator: (name) {
                    return Validate.phone(name, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.phoneNumber = value!.trim();
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration:
                            const InputDecoration(label: Text('Blood Group')),
                        value: widget.user.medicalInfo.bloodGroup,
                        items: BloodGroup.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          widget.user.medicalInfo.bloodGroup = value;
                        },
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          label: Text('RH Blood Type'),
                        ),
                        value: widget.user.medicalInfo.rhBloodType,
                        items: RhBloodType.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          widget.user.medicalInfo.rhBloodType = value;
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    label: Text("Height"),
                  ),
                  initialValue: widget.user.medicalInfo.height == null
                      ? null
                      : widget.user.medicalInfo.height!.toString(),
                  validator: (name) {
                    return Validate.integer(name, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.height =
                        int.tryParse(value!.trim());
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    label: Text("Weight"),
                  ),
                  initialValue: widget.user.medicalInfo.weight == null
                      ? null
                      : widget.user.medicalInfo.weight!.toString(),
                  validator: (name) {
                    return Validate.integer(name, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.weight =
                        int.tryParse(value!.trim());
                  },
                ),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    label: Text('Sex'),
                  ),
                  value: widget.user.medicalInfo.sex,
                  items: Sex.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    widget.user.medicalInfo.sex = value;
                  },
                ),
                DropdownButtonFormField(
                  decoration:
                      const InputDecoration(label: Text('Organ Donor?')),
                  value: widget.user.medicalInfo.organDonor,
                  items: [true, false]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e ? "Yes" : "No"),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    widget.user.medicalInfo.organDonor = value ?? false;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date of Birth'),
                    ElevatedButton.icon(
                      label: Text(widget.user.medicalInfo.dob != null
                          ? ddmmyyyy(widget.user.medicalInfo.dob!)
                          : "Click to choose"),
                      onPressed: () async {
                        final chosenDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.utc(1900),
                          lastDate: DateTime.now(),
                        );
                        setState(() {
                          widget.user.medicalInfo.dob =
                              chosenDate ?? widget.user.medicalInfo.dob;
                        });
                      },
                      icon: const Icon(Icons.date_range_rounded),
                    ),
                  ],
                ),
              ]),
              Section(title: 'Health Information', children: [
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    label: Text("Allergies"),
                  ),
                  initialValue: widget.user.medicalInfo.allergies,
                  validator: (value) {
                    return Validate.text(value, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.allergies = value!.trim();
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    label: Text("Medical Conditions"),
                  ),
                  initialValue: widget.user.medicalInfo.medicalConditions,
                  validator: (value) {
                    return Validate.text(value, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.medicalConditions = value!.trim();
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    label: Text("Medications"),
                  ),
                  initialValue: widget.user.medicalInfo.medications,
                  validator: (value) {
                    return Validate.text(value, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.medications = value!.trim();
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    label: Text("Remarks"),
                  ),
                  initialValue: widget.user.medicalInfo.remarks,
                  validator: (value) {
                    return Validate.text(value, required: false);
                  },
                  onSaved: (value) {
                    widget.user.medicalInfo.remarks = value!.trim();
                  },
                ),
              ]),
              if (currentUser.isAdmin)
                Section(
                  title: 'Permissions',
                  children: [
                    PermissionWidget(
                      user: widget.user,
                      type: 'Attendance',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) =>
                          widget.user.permissions.attendance = crud,
                    ),
                    PermissionWidget(
                      user: widget.user,
                      type: 'categories',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) =>
                          widget.user.permissions.categories = crud,
                    ),
                    PermissionWidget(
                      user: widget.user,
                      type: 'complaints',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) =>
                          widget.user.permissions.complaints = crud,
                    ),
                    PermissionWidget(
                      user: widget.user,
                      type: 'requests',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) =>
                          widget.user.permissions.requests = crud,
                    ),
                    PermissionWidget(
                      user: widget.user,
                      type: 'users',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) => widget.user.permissions.users = crud,
                    ),
                    PermissionWidget(
                      user: widget.user,
                      type: 'approvers',
                      expanded: false,
                      showSaveButton: false,
                      onChange: (crud) =>
                          widget.user.permissions.approvers = crud,
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  LoadingElevatedButton(
                    onPressed: () async {
                      await save(context);
                    },
                    icon: Icon(
                      widget.user.email == null
                          ? Icons.person_add_rounded
                          : Icons.save_rounded,
                    ),
                    label: Text(widget.user.email == null ? 'Add' : 'Save'),
                  ),
                  TextButton.icon(
                    onPressed: () => _formKey.currentState!.reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
