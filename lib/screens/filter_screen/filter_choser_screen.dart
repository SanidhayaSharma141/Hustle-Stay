import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustle_stay/models/category/category.dart';
import 'package:hustle_stay/models/complaint/complaint.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/providers/settings.dart';
import 'package:hustle_stay/screens/filter_screen/select_one_tile.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/selection_vault.dart';

class FilterChooserScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  const FilterChooserScreen({super.key, required this.filters});

  @override
  ConsumerState<FilterChooserScreen> createState() =>
      _FilterChooserScreenState();
}

class _FilterChooserScreenState extends ConsumerState<FilterChooserScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsClass = ref.read(settingsProvider.notifier);
    final filterWidgets = [
      CreatedWithin(
          dateRange: widget.filters['createdWithin'],
          onChange: (dateRange) {
            widget.filters['createdWithin'] = dateRange;
            settingsClass.saveSettings();
          }),
      ResolvedChoose(
          resolved: widget.filters['resolved'],
          onChange: (resolved) {
            setState(() {
              widget.filters['resolved'] = resolved;
            });
            settingsClass.saveSettings();
          }),
      if (widget.filters['resolved'] == true)
        ResolvedWithin(
            dateRange: widget.filters['resolvedWithin'],
            onChange: (dateRange) {
              widget.filters['resolvedWithin'] = dateRange;
              settingsClass.saveSettings();
            }),
      ScopeChooser(
          scope: widget.filters['scope'],
          onChange: (scope) {
            widget.filters['scope'] = scope;
            settingsClass.saveSettings();
          }),
      // SelectOne<String>(
      //   title: 'Deleted?',
      //   allOptions: const {'True', 'False', 'Any'},
      //   onChange: (chosenOption) {
      //     widget.filters['deleted'] = chosenOption == 'Any'
      //         ? null
      //         : (chosenOption[0] == 'D' ? true : false);
      //     return true;
      //   },
      //   selectedOption: (widget.filters['deleted'] == null
      //       ? 'Any'
      //       : (widget.filters['deleted'] ? 'True' : 'False')),
      // ),
      CategoriesBuilder(
        src: Source.cache,
        loadingWidget: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: circularProgressIndicator(),
          ),
        ),
        builder: (ctx, categories) => CategoryChooser(
            onChange: ((chosenCategories) {
              widget.filters['categories'] = chosenCategories;
              settingsClass.saveSettings();
            }),
            allCategories: categories.map((e) => e.id).toSet(),
            chosenCategories: widget.filters['categories'] ?? {}),
      ),
      UsersBuilder(
        loadingWidget: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: circularProgressIndicator(),
          ),
        ),
        builder: (ctx, users) {
          final Map<String, Set<String>> hostels = {};
          users.where((element) => element.hostelName != null).forEach((e) =>
              hostels[e.hostelName!] = (hostels[e.hostelName!] ?? {})
                ..add(e.email!));

          final students = users
              .where((element) => element.type == 'student')
              .map((e) => e.email!)
              .toSet();
          students.add('code_soc@students.iiitr.ac.in');

          return ComplainantChooser(
            hostels: hostels,
            allUsers: students,
            onChange: (users) {
              widget.filters['complainants'] = users.map((e) => e).toSet();
              settingsClass.saveSettings();
            },
            chosenUsers: widget.filters['complainants'] ?? {},
          );
        },
      ),
      UsersBuilder(
        provider: fetchComplainees,
        loadingWidget: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: circularProgressIndicator(),
          ),
        ),
        builder: (ctx, users) => ComplaineeChooser(
          allUsers: users.map((e) => e.email!).toSet(),
          onChange: (users) {
            widget.filters['complainees'] = users;
            settingsClass.saveSettings();
          },
          chosenUsers: widget.filters['complainees'] ?? {},
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () {
              // widget.filters.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          /// Updating all cached information
          await fetchUsers();
          await fetchAllCategories();
          await fetchComplainees();
        },
        child: ListView.separated(
          itemCount: filterWidgets.length,
          separatorBuilder: (ctx, index) => const Divider(),
          itemBuilder: (ctx, index) => Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8),
            child: filterWidgets[index],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String txt;
  const _Title(this.txt);

  @override
  Widget build(BuildContext context) {
    return Text(
      txt,
      style: Theme.of(context)
          .textTheme
          .titleMedium!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ignore: must_be_immutable
class CreatedWithin extends StatefulWidget {
  final void Function(DateTimeRange? dateRange) onChange;
  DateTimeRange? dateRange;
  CreatedWithin({
    super.key,
    required this.onChange,
    this.dateRange,
  });

  @override
  State<CreatedWithin> createState() => _CreatedWithinState();
}

class _CreatedWithinState extends State<CreatedWithin> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int i = 0;
    int selectedIndex = 0;

    if (widget.dateRange == null) {
      selectedIndex = 4;
    } else if (widget.dateRange!.end.day == DateTime.now().day) {
      final duration =
          widget.dateRange!.end.difference(widget.dateRange!.start);
      if (duration.inDays == 7) {
        selectedIndex = 1;
      } else if (duration.inDays == 30) {
        selectedIndex = 2;
      } else if (duration.inDays == 365) {
        selectedIndex = 3;
      } else {
        selectedIndex = 5;
      }
    } else if (widget.dateRange!.end == DateTime(now.year, now.month, 1) &&
        widget.dateRange!.start == DateTime(now.year, now.month - 1, 1)) {
      selectedIndex = 0;
    } else {
      selectedIndex = 5;
    }

    /// The items in this filter
    final items = [
      SelectOneTile(
        label: 'Last month',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              start: DateTime(now.year, now.month - 1, 1),
              end: DateTime(now.year, now.month, 1),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 7 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 7),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 30 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 30),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 365 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 365),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'All Time',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = null;
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: (selectedIndex == i
            ? '${ddmmyyyy(widget.dateRange!.start)} - ${ddmmyyyy(widget.dateRange!.end)}'
            : 'Custom'),
        isSelected: selectedIndex == i++,
        onPressed: () async {
          final dateRange = await showDateRangePicker(
            context: context,
            initialDateRange: widget.dateRange,
            helpText: 'Select 2 dates',
            firstDate: DateTime.utc(1997),
            lastDate: DateTime.now(),
          );
          if (dateRange != null) {
            setState(() {
              widget.dateRange = dateRange;
            });
            widget.onChange(widget.dateRange);
          }
        },
      ),
    ];

    final children = [
      Row(
        children: [
          const _Title('Created within'),
          IconButton(
            onPressed: () {
              setState(() {
                expanded = !expanded;
              });
            },
            icon: Icon(expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
      if (expanded)
        Wrap(children: items)
      else
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (ctx, index) => const SizedBox(width: 5),
            itemBuilder: (ctx, index) => items[index],
            itemCount: items.length,
          ),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ignore: must_be_immutable
class ResolvedWithin extends StatefulWidget {
  final void Function(DateTimeRange? dateRange) onChange;
  DateTimeRange? dateRange;
  ResolvedWithin({
    super.key,
    required this.onChange,
    this.dateRange,
  });

  @override
  State<ResolvedWithin> createState() => _ResolvedWithinState();
}

class _ResolvedWithinState extends State<ResolvedWithin> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int i = 0;
    int selectedIndex = 0;

    if (widget.dateRange == null) {
      selectedIndex = 4;
    } else if (widget.dateRange!.end.day == DateTime.now().day) {
      final duration =
          widget.dateRange!.end.difference(widget.dateRange!.start);
      if (duration.inDays == 7) {
        selectedIndex = 1;
      } else if (duration.inDays == 30) {
        selectedIndex = 2;
      } else if (duration.inDays == 365) {
        selectedIndex = 3;
      } else {
        selectedIndex = 5;
      }
    } else if (widget.dateRange!.end == DateTime(now.year, now.month, 1) &&
        widget.dateRange!.start == DateTime(now.year, now.month - 1, 1)) {
      selectedIndex = 0;
    } else {
      selectedIndex = 5;
    }

    /// The items in this filter
    final items = [
      SelectOneTile(
        label: 'Last month',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              start: DateTime(now.year, now.month - 1, 1),
              end: DateTime(now.year, now.month, 1),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 7 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 7),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 30 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 30),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'Last 365 Days',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = DateTimeRange(
              end: DateTime(now.year, now.month, now.day),
              start: DateTime(now.year, now.month, now.day - 365),
            );
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: 'All Time',
        isSelected: selectedIndex == i++,
        onPressed: () {
          setState(() {
            widget.dateRange = null;
          });
          widget.onChange(widget.dateRange);
        },
      ),
      SelectOneTile(
        label: (selectedIndex == i
            ? '${ddmmyyyy(widget.dateRange!.start)} - ${ddmmyyyy(widget.dateRange!.end)}'
            : 'Custom'),
        isSelected: selectedIndex == i++,
        onPressed: () async {
          final dateRange = await showDateRangePicker(
            context: context,
            initialDateRange: widget.dateRange,
            helpText: 'Select 2 dates',
            firstDate: DateTime.utc(1997),
            lastDate: DateTime.now(),
          );
          if (dateRange != null) {
            setState(() {
              widget.dateRange = dateRange;
            });
            widget.onChange(widget.dateRange);
          }
        },
      ),
    ];

    final children = [
      Row(
        children: [
          const _Title('Resolved within'),
          IconButton(
            onPressed: () {
              setState(() {
                expanded = !expanded;
              });
            },
            icon: Icon(expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
      if (expanded)
        Wrap(children: items)
      else
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (ctx, index) => const SizedBox(width: 5),
            itemBuilder: (ctx, index) => items[index],
            itemCount: items.length,
          ),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ignore: must_be_immutable
class ScopeChooser extends StatefulWidget {
  Scope? scope;
  final void Function(Scope? scope) onChange;
  ScopeChooser({super.key, this.scope, required this.onChange});

  @override
  State<ScopeChooser> createState() => _ScopeChooserState();
}

class _ScopeChooserState extends State<ScopeChooser> {
  @override
  Widget build(BuildContext context) {
    /// The items in this filter
    final items = [
      SelectOneTile(
        label: 'Private',
        isSelected: widget.scope == Scope.private || widget.scope == null,
        onPressed: () {
          setState(() {
            if (widget.scope == Scope.private) widget.scope = null;
            widget.scope = widget.scope == Scope.public ? null : Scope.public;
          });
          widget.onChange(widget.scope);
        },
      ),
      SelectOneTile(
        label: 'Public',
        isSelected: widget.scope == Scope.public || widget.scope == null,
        onPressed: () {
          setState(() {
            if (widget.scope == Scope.public) widget.scope = null;
            widget.scope = widget.scope == Scope.private ? null : Scope.private;
          });
          widget.onChange(widget.scope);
        },
      )
    ];

    final children = [
      const SizedBox(height: 8),
      const _Title('Scope'),
      const SizedBox(height: 8),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (ctx, index) => const SizedBox(width: 5),
          itemBuilder: (ctx, index) => items[index],
          itemCount: items.length,
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ignore: must_be_immutable
class ResolvedChoose extends StatefulWidget {
  bool? resolved;
  final void Function(bool? resolved) onChange;
  ResolvedChoose({super.key, this.resolved, required this.onChange});

  @override
  State<ResolvedChoose> createState() => _ResolvedChooseState();
}

class _ResolvedChooseState extends State<ResolvedChoose> {
  @override
  Widget build(BuildContext context) {
    /// The items in this filter
    final items = [
      SelectOneTile(
        label: 'Resolved',
        isSelected: widget.resolved == true || widget.resolved == null,
        onPressed: () {
          setState(() {
            if (widget.resolved == true) widget.resolved = null;
            widget.resolved = widget.resolved == false ? null : false;
          });
          widget.onChange(widget.resolved);
        },
      ),
      SelectOneTile(
        label: 'Pending',
        isSelected: widget.resolved == false || widget.resolved == null,
        onPressed: () {
          setState(() {
            if (widget.resolved == false) widget.resolved = null;
            widget.resolved = widget.resolved == true ? null : true;
          });
          widget.onChange(widget.resolved);
        },
      ),
    ];

    final children = [
      const SizedBox(height: 8),
      const _Title('Status'),
      const SizedBox(height: 8),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (ctx, index) => const SizedBox(width: 5),
          itemBuilder: (ctx, index) => items[index],
          itemCount: items.length,
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ignore: must_be_immutable
class ComplainantChooser extends StatefulWidget {
  final void Function(Set<String> chosenUsers) onChange;
  final Set<String> allUsers;
  Set<String> chosenUsers;
  final Map<String, Set<String>> hostels;
  ComplainantChooser({
    super.key,
    required this.onChange,
    required this.allUsers,
    required this.chosenUsers,
    this.hostels = const {},
  });

  @override
  State<ComplainantChooser> createState() => _ComplainantChooserState();
}

class _ComplainantChooserState extends State<ComplainantChooser> {
  @override
  Widget build(BuildContext context) {
    final keys = widget.hostels.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const _Title('Complainants'),
        const SizedBox(height: 8),
        SelectionVault(
          helpText: 'Add a Complainant',
          onChange: (users) {
            widget.chosenUsers = users;
            widget.onChange(users);
          },
          allItems: widget.allUsers,
          chosenItems: widget.chosenUsers,
        ),
        if (widget.hostels.isNotEmpty) const SizedBox(height: 8),
        if (widget.hostels.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (ctx, index) => const SizedBox(width: 5),
              itemBuilder: (ctx, index) => OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(keys[index]),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).dividerColor),
                onPressed: () {
                  setState(() {
                    widget.chosenUsers.addAll(widget.hostels[keys[index]]!);
                  });
                  widget.onChange(widget.chosenUsers);
                },
              ),
              itemCount: widget.hostels.length,
            ),
          ),
      ],
    );
  }
}

class ComplaineeChooser extends StatelessWidget {
  final void Function(Set<String> chosenUsers) onChange;
  final Set<String> allUsers;
  final Set<String> chosenUsers;
  final String title;
  final String helpText;
  const ComplaineeChooser({
    super.key,
    required this.onChange,
    required this.allUsers,
    required this.chosenUsers,
    this.title = 'Complainees',
    this.helpText = 'Add a Complainee',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _Title(title),
        const SizedBox(height: 8),
        SelectionVault(
          helpText: helpText,
          onChange: onChange,
          allItems: allUsers,
          chosenItems: chosenUsers,
        ),
      ],
    );
  }
}

class CategoryChooser extends StatelessWidget {
  final void Function(Set<String> chosenCategories) onChange;
  final Set<String> allCategories;
  final Set<String> chosenCategories;
  const CategoryChooser({
    super.key,
    required this.onChange,
    required this.allCategories,
    required this.chosenCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const _Title('Categories'),
        const SizedBox(height: 8),
        SelectionVault(
          helpText: 'Add a Category',
          onChange: onChange,
          allItems: allCategories,
          chosenItems: chosenCategories,
        ),
      ],
    );
  }
}
