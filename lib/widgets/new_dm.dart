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
        _allUsers.removeWhere((user) => user.userId == store.selfUserId);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    return _allUsers.where((user) =>
        user.fullName.toLowerCase().contains(query)
    ).toList();
  }

  void _handleUserSelect(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
      _searchController.clear();
    });
    Future.delayed(const Duration(milliseconds: 10), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
      backgroundColor: designVariables.bgContextMenu,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.chevron_left, color: designVariables.icon, size: 24),
                  Text('Back', style: TextStyle(color: designVariables.icon, fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(), // Pushes the title to the center
            const Text('New DM', textAlign: TextAlign.center),
            const Spacer(), // Ensures title stays centered
          ],
        ),
        centerTitle: false, // Prevents default centering when using custom layout
        actions: [
          TextButton(
            onPressed: _selectedUsers.isEmpty ? null : _handleDone,
            child: Row(
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: _selectedUsers.isEmpty ? designVariables.icon.withValues(alpha: 0.5) : designVariables.icon,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.chevron_right, color: _selectedUsers.isEmpty ? designVariables.icon.withValues(alpha: 0.5) : designVariables.icon, size: 24),
              ],
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
                color: designVariables.bgSearchInput,
                constraints: BoxConstraints(
                  minWidth: double.infinity,
                  maxHeight: screenHeight * 0.2, // Limit height to 20% of screen
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14,11,14,0),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      children: [
                        ..._selectedUsers.map((user) => Chip(
                          avatar: Avatar(userId: user.userId, size: 22, borderRadius: 3),
                          label: Text(user.fullName, style: TextStyle(fontSize: 16, color: designVariables.labelMenuButton)),
                          deleteIcon: null,
                          backgroundColor: designVariables.bgMenuButtonSelected,
                          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1), // Adjust padding to control height
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
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
                final isSelected = _selectedUsers.contains(user); // Check if user is selected

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: isSelected ? designVariables.bgMenuButtonSelected : designVariables.bgContextMenu,
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? designVariables.radioFillSelected : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Avatar(userId: user.userId, size: 32, borderRadius: 3),
                            if (user.isActive)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: designVariables.statusOnline,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? designVariables.bgMenuButtonSelected: designVariables.bgContextMenu, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    title: Text(user.fullName, style: TextStyle(color: designVariables.textMessage, fontSize: 17, fontWeight: FontWeight.w500)),
                    onTap: () => _handleUserSelect(user),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
