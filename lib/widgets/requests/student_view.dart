import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:hustle_stay/models/requests/request.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/providers/firestore_cache_builder.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/requests/post_request_options.dart';

class RequestsList extends StatefulWidget {
  final List<Request> requests;
  final bool showPostRequestOptions;
  const RequestsList({
    super.key,
    this.requests = const [],
    this.showPostRequestOptions = true,
  });

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        try {
          if (widget.requests.isEmpty) {
            await initializeRequests();
          }
        } catch (e) {
          showMsg(context, e.toString());
        }
        setState(() {});
      },
      child: ListView(
        children: [
          if (currentUser.permissions.requests.create == true &&
              widget.showPostRequestOptions)
            const PostRequestOptions(),
          CacheBuilder(
            loadingWidget: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: circularProgressIndicator(),
              ),
            ),
            builder: (ctx, data) {
              data.sort(
                (a, b) {
                  return a.id < b.id ? 1 : 0;
                },
              );
              final children = data.map((e) => e.widget(context)).toList();
              if (children.isEmpty && currentUser.type != 'student') {
                return SizedBox(
                  height: mediaQuery.size.height -
                      mediaQuery.viewInsets.top -
                      mediaQuery.padding.top -
                      mediaQuery.padding.bottom -
                      mediaQuery.viewInsets.bottom -
                      150,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimateIcon(
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {},
                          iconType: IconType.continueAnimation,
                          animateIcon: AnimateIcons.cool,
                        ),
                        Text(
                          'No requests are pending',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (children.isNotEmpty) {
                children.insert(
                  0,
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, top: 20, bottom: 5),
                    child: shaderText(
                      context,
                      title:
                          '${currentUser.type == 'student' ? 'Your' : 'Pending'} Requests',
                      style: theme.textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return ListView.separated(
                separatorBuilder: (ctx, index) {
                  return const SizedBox(
                    height: 10,
                  );
                },
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: children.length,
                itemBuilder: (ctx, index) {
                  return children[index];
                },
              );
            },
            provider: widget.requests.isEmpty
                ? ({src}) => fetchRequests()
                : ({src}) async => widget.requests,
          ),
          const SizedBox(height: 35),
        ],
      ),
    );
  }
}
