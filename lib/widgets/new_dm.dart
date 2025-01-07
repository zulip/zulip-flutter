import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../model/narrow.dart';
import 'content.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'theme.dart';

class NewDmScreen extends StatefulWidget {
  const NewDmScreen({super.key});

  static Route<void> buildRoute({int? accountId, BuildContext? context}) {
    return MaterialAccountWidgetRoute(
        accountId: accountId,
        context: context,
        page: const NewDmScreen()
    );
  }

  @override
  State<NewDmScreen> createState() => _NewDmScreenState();
}

class _NewDmScreenState extends State<NewDmScreen> {
  final List<User> _selectedUsers = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();


  List<User> _allUsers = [];
  bool _isLoading = true;
  bool _isDataFetched = false; // To ensure `_fetchUsers` is called only once

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isDataFetched) {
      _isDataFetched = true; // Avoid calling `_fetchUsers` multiple times
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final store = PerAccountStoreWidget.of(context);
      final usersMap = store.users;
      setState(() {
        _allUsers = usersMap.values.toList();
        _isLoading = false;
      });
      print('Fetched ${_allUsers.length} users');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      print('Error fetching users: $error');
    }
  }

  List<User> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    return _allUsers.where((user) =>
    !_selectedUsers.contains(user) &&
        user.fullName.toLowerCase().contains(query)
    ).toList();
  }

  void _handleUserSelect(User user) {
    setState(() {
      _selectedUsers.add(user);
      _searchController.clear();
    });
    Future.delayed(Duration(milliseconds: 10), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _handleUserRemove(User user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  void _handleDone() {
    if (_selectedUsers.isNotEmpty) {
      final store = PerAccountStoreWidget.of(context);
      final narrow = DmNarrow.withOtherUsers(
        _selectedUsers.map((u) => u.userId),
        selfUserId: store.selfUserId,
      );
      Navigator.pushReplacement(context,
          MessageListPage.buildRoute(context: context, narrow: narrow));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    DesignVariables designVariables = DesignVariables.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New DM'),
        actions: [
          TextButton(
            onPressed: _selectedUsers.isEmpty ? null : _handleDone,
            child: Text(
              'Next',
              style: TextStyle(
                color: _selectedUsers.isEmpty
                    ? Colors.grey
                    : designVariables.icon,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: const Color(0xff313131),
                constraints: BoxConstraints(
                  minWidth: double.infinity,
                  maxHeight: screenHeight * 0.2, // Limit height to 20% of screen
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    child: Wrap(
                      spacing: 5,
                      children: [
                        ..._selectedUsers.map((user) => Chip(
                          avatar: Avatar(userId: user.userId, size: 32, borderRadius: 3),
                          label: Text(user.fullName),
                          onDeleted: () => _handleUserRemove(user),
                          backgroundColor: Color(0xFF40000000),
                        )),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Add person',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedUsers.contains(user)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _selectedUsers.contains(user)
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8), // Add spacing between the icon and avatar
                      Avatar(userId: user.userId, size: 32, borderRadius: 3),
                    ],
                  ),
                  title: Text(user.fullName),
                  onTap: () => _handleUserSelect(user),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
