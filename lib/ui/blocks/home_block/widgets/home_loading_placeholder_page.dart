import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/global_service.dart';
import '../../../app.dart';
import '../../../utils/page.dart';

const kTryAnotherAccountWaitPeriod = Duration(seconds: 5);

class HomeLoadingPlaceholderPage extends StatefulWidget {
  const HomeLoadingPlaceholderPage({super.key, required this.accountId});

  final int accountId;

  @override
  State<HomeLoadingPlaceholderPage> createState() =>
      _LoadingPlaceholderPageState();
}

class _LoadingPlaceholderPageState extends State<HomeLoadingPlaceholderPage> {
  Timer? tryAnotherAccountTimer;
  bool showTryAnotherAccount = false;

  @override
  void initState() {
    super.initState();
    tryAnotherAccountTimer = Timer(kTryAnotherAccountWaitPeriod, () {
      setState(() {
        showTryAnotherAccount = true;
      });
    });
  }

  @override
  void dispose() {
    tryAnotherAccountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final account = GlobalService.to.getAccount(widget.accountId);

    if (account == null) {
      // We should only reach this state very briefly.
      // See [_LoadingPlaceholderPage.accountId].
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            Visibility(
              visible: showTryAnotherAccount,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      textAlign: TextAlign.center,
                      zulipLocalizations.tryAnotherAccountMessage(
                        account.realmUrl.toString(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialWidgetRoute(page: const ChooseAccountPage()),
                      ),
                      child: Text(zulipLocalizations.tryAnotherAccountButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
