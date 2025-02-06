import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';
import 'app_bar.dart';
import 'store.dart';
import 'theme.dart';

class RecentDMUsersPage extends StatefulWidget {
  const RecentDMUsersPage({super.key, required this.recepientIds});

  final List<int> recepientIds;

  @override
  State<RecentDMUsersPage> createState() => _RecentDMUsersPageState();
}

class _RecentDMUsersPageState extends State<RecentDMUsersPage> {
  @override
  void initState() {
    super.initState();
    _recepientIds.addAll(widget.recepientIds);
  }

  final TextEditingController _searchController = TextEditingController();

  final _recepientIds = List<int>.empty(growable: true);

  void _searchUsersByName(String? name, Map<int, User> users) {
    if (name != null && name.isEmpty) {
      _recepientIds.clear();
      _recepientIds.addAll(widget.recepientIds);
    }

    final newUsers =
        users.values
            .where((e) => widget.recepientIds.contains(e.userId))
            .toList();

    if (name != null && name.isNotEmpty) {
      _recepientIds.clear();
      final filteredUsers =
          newUsers
              .where(
                (user) =>
                    user.fullName.toLowerCase().contains(name.toLowerCase()),
              )
              .toList();
      _recepientIds.addAll(filteredUsers.map((e) => e.userId));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    return Scaffold(
      appBar: ZulipAppBar(
        centerTitle: true,
        title: Text('${widget.recepientIds.length} users'),
      ),

      body: Column(
        children: [
          Container(
            height: 44,
            width: MediaQuery.of(context).size.width,
            color: designVariables.bgSearchInput,
            child: TextFormField(
              controller: _searchController,
              onChanged: (query) {
                _searchUsersByName(query, store.users);
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Filter users',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final user = store.users[_recepientIds[index]];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.all(12),
                leading: Image.network(
                  user?.avatarUrl ?? "",
                  width: 32,
                  height: 32,
                ),
                title: Text(
                  user?.fullName ?? "",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
            itemCount: _recepientIds.length,
          ),
        ],
      ),
    );
  }
}
