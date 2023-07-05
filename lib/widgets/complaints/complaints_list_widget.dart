import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hustle_stay/models/complaint/complaint.dart';
import 'package:hustle_stay/widgets/complaints/complaint_list_item.dart';

class ComplaintsListWidget extends StatelessWidget {
  final List<ComplaintData> complaints;
  const ComplaintsListWidget({super.key, required this.complaints});

  @override
  Widget build(BuildContext context) {
    int i = 0;
    final mediaQuery = MediaQuery.of(context);
    const duration = Duration(milliseconds: 400);
    return complaints.isEmpty
        ? ListView(
            children: [
              SizedBox(
                height: mediaQuery.size.height -
                    mediaQuery.viewInsets.top -
                    mediaQuery.padding.top -
                    mediaQuery.padding.bottom -
                    mediaQuery.viewInsets.bottom -
                    150,
                child: Center(
                  child: Text(
                    'All clear✨',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          )
        : ListView.builder(
            itemBuilder: (ctx, index) {
              final complaint = complaints[index];
              return ComplaintListItem(
                complaint: complaint,
              ).animate(onComplete: (controller) {
                i--;
              });
            },
            itemCount: complaints.length,
          );
  }
}
