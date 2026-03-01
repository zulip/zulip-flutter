import 'package:flutter/material.dart';

import '../api/route/channels.dart';
import '../widgets/store.dart';
import 'page.dart';

class CreateChannelPage extends StatefulWidget {
  const CreateChannelPage({super.key});

  static Route<void> buildRoute(BuildContext context) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: const CreateChannelPage(),
    );
  }

  @override
  State<CreateChannelPage> createState() => _CreateChannelPageState();
}

class _CreateChannelPageState extends State<CreateChannelPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String privacy = "Public";
  bool isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final store = PerAccountStoreWidget.of(context);

    setState(() {
      isLoading = true;
    });

    try {
      await subscribeToChannel(
        store.connection,
        subscriptions: [nameController.text.trim()],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Channel created")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to create channel. Please check permissions."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create channel")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Channel Name (Required)
              const Text(
                "Channel name *",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Add a channel name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Channel name is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// Description
              const Text(
                "Description",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Type your description here…",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// Privacy Dropdown
              const Text(
                "Privacy",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: privacy,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Public", child: Text("Public")),
                  DropdownMenuItem(value: "Private", child: Text("Private")),
                ],
                onChanged: (value) {
                  setState(() {
                    privacy = value!;
                  });
                },
              ),

              const Spacer(),

              /// Create Channel Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create channel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
