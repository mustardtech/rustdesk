import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../consts.dart';
import '../../models/platform_model.dart';
import '../../models/server_model.dart';
import '../pages/server_page.dart' show checkClickTime;
import 'mustard_theme.dart';

enum MustardCmState { request, active, ended }

class MustardCmAction {
  final String label;
  final VoidCallback onTap;

  const MustardCmAction(this.label, this.onTap);
}

List<String> mustardAbilities(Client client) {
  switch (client.type_()) {
    case ClientType.file:
      return const ['Send and receive files'];
    case ClientType.terminal:
      return const ['Run commands in a terminal'];
    case ClientType.portForward:
      return ['Open a network connection (${client.portForward})'];
    case ClientType.camera:
      return [
        'See your camera',
        if (client.audio) 'Hear your computer\'s sound',
        if (client.recording) 'Record the session',
      ];
    case ClientType.remote:
      return [
        'See your screen',
        if (client.keyboard) 'Use your keyboard and mouse',
        if (client.clipboard) 'Copy and paste text',
        if (client.file) 'Send and receive files',
        if (client.audio) 'Hear your computer\'s sound',
        if (client.restart) 'Restart your computer',
        if (client.recording) 'Record the session',
        if (client.blockInput) 'Pause your keyboard and mouse',
      ];
  }
}

String mustardElapsed(int seconds) {
  two(int n) => n.toString().padLeft(2, '0');
  final h = seconds ~/ 3600;
  final rest = '${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
  return h > 0 ? '${two(h)}:$rest' : rest;
}

/// What the person at the computer sees while a technician asks to connect,
/// is connected, or has left. It takes plain values so it can be drawn
/// without a running session.
class MustardConnectionView extends StatelessWidget {
  final String name;
  final String peerId;
  final MustardCmState state;
  final bool canAccept;
  final List<String> abilities;
  final int elapsedSeconds;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onEnd;
  final VoidCallback? onClose;
  final List<MustardCmAction> actions;

  const MustardConnectionView({
    super.key,
    required this.name,
    required this.peerId,
    required this.state,
    this.canAccept = true,
    this.abilities = const [],
    this.elapsedSeconds = 0,
    this.onAccept,
    this.onDecline,
    this.onEnd,
    this.onClose,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = MustardColors.of(context);
    return DefaultTextStyle.merge(
      style: TextStyle(fontFamily: kMustardFont, color: c.text, fontSize: 13),
      child: Container(
        color: c.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state == MustardCmState.active) _banner(c),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._heading(c),
                    _technician(c),
                    if (state != MustardCmState.ended && abilities.isNotEmpty)
                      ..._abilities(c),
                    if (state == MustardCmState.active)
                      Text(
                        'Please leave this computer on while we work. You can '
                        'end the session at any time.',
                        style: TextStyle(
                            fontSize: 12.5, height: 1.5, color: c.dim),
                      ).marginOnly(top: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final action in actions)
                    OutlinedButton(
                      style: mustardSubtleButton(c,
                          height: kMustardLargeButtonHeight),
                      onPressed: action.onTap,
                      child: Text(action.label),
                    ).marginOnly(bottom: 10),
                  _buttons(c),
                  if (state != MustardCmState.ended) _phone(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(MustardColors c) => Container(
        color: c.gold,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: c.onGold, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Support session in progress',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.onGold),
              ),
            ),
            Text(
              mustardElapsed(elapsedSeconds),
              style: TextStyle(
                fontSize: 13,
                color: c.onGold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );

  List<Widget> _heading(MustardColors c) {
    final String title;
    final String? note;
    switch (state) {
      case MustardCmState.request:
        title = canAccept
            ? 'A technician wants to connect'
            : 'A technician is connecting';
        note = canAccept
            ? 'Only accept if you are on the phone with Mustard right now.'
            : 'They need your password to continue. Decline if you are not '
                'expecting this.';
        break;
      case MustardCmState.active:
        return const [];
      case MustardCmState.ended:
        title = 'Session ended';
        note = 'The technician has disconnected and can no longer see this '
            'computer.';
        break;
    }
    return [
      Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      ),
      Text(
        note,
        style: TextStyle(fontSize: 13.5, height: 1.5, color: c.dim),
      ).marginOnly(top: 6, bottom: 20),
    ];
  }

  Widget _technician(MustardColors c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(kMustardCardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: c.gold, shape: BoxShape.circle),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.onGold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.trim().isEmpty ? 'Technician' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID ${formatID(peerId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.dim,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  List<Widget> _abilities(MustardColors c) => [
        Text(
          state == MustardCmState.active
              ? 'RIGHT NOW THEY CAN'
              : 'THEY WILL BE ABLE TO',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: c.dim),
        ).marginOnly(top: 20, bottom: 4),
        for (final ability in abilities)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 16, color: c.accent)
                  .marginOnly(top: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(ability,
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
              ),
            ],
          ).marginOnly(top: 6),
      ];

  Widget _buttons(MustardColors c) {
    const height = kMustardLargeButtonHeight;
    switch (state) {
      case MustardCmState.request:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: mustardSubtleButton(c, height: height),
                onPressed: onDecline,
                child: const Text('Decline'),
              ),
            ),
            if (canAccept) const SizedBox(width: 10),
            if (canAccept)
              Expanded(
                child: ElevatedButton(
                  style: mustardPrimaryButton(c, height: height),
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
          ],
        );
      case MustardCmState.active:
        return ElevatedButton(
          style: mustardDangerButton(c, height: height),
          onPressed: onEnd,
          child: const Text('End session'),
        );
      case MustardCmState.ended:
        return ElevatedButton(
          style: mustardPrimaryButton(c, height: height),
          onPressed: onClose,
          child: const Text('Close'),
        );
    }
  }

  Widget _phone(MustardColors c) => Text.rich(
        TextSpan(
          text: state == MustardCmState.request
              ? 'Not expecting this? Decline and call '
              : 'Need to talk to us? Call ',
          children: [
            TextSpan(
              text: kMustardPhone,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: c.dim),
      ).marginOnly(top: 12);
}

/// Connects [MustardConnectionView] to a live connection. The calls mirror
/// the stock connection manager's header and control panel.
class MustardConnectionCard extends StatefulWidget {
  final Client client;

  const MustardConnectionCard({super.key, required this.client});

  @override
  State<MustardConnectionCard> createState() => _MustardConnectionCardState();
}

class _MustardConnectionCardState extends State<MustardConnectionCard>
    with AutomaticKeepAliveClientMixin {
  Client get client => widget.client;

  final _time = 0.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (client.authorized && !client.disconnected) {
        _time.value = _time.value + 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gFFI.serverModel.tabController.onSelected?.call(client.id.toString());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _guarded(VoidCallback action) => checkClickTime(client.id, action);

  void _elevate(ServerModel model) {
    model.setShowElevation(false);
    bind.cmElevatePortable(connId: client.id);
  }

  Future<void> _close() async {
    await bind.cmRemoveDisconnectedConnection(connId: client.id);
    if (await bind.cmGetClientsLength() == 0) {
      windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ServerModel>(builder: (context, model, child) {
      final state = !client.authorized
          ? MustardCmState.request
          : client.disconnected
              ? MustardCmState.ended
              : MustardCmState.active;
      final canAccept = model.approveMode != 'password';
      final isRemote = client.type_() == ClientType.remote;
      var canElevate = bind.cmCanElevate() && model.showElevation && isRemote;
      if (state == MustardCmState.request) {
        canElevate = canElevate &&
            canAccept &&
            bind.mainGetBuildinOption(
                    key: kOptionHideElevateButtonInAcceptWindow) !=
                'Y';
      }
      final keepOpen = appName == 'MustardSupport';
      final actions = <MustardCmAction>[
        if (state == MustardCmState.request && canElevate)
          MustardCmAction('Accept with administrator access', () {
            _guarded(() {
              model.sendLoginResponse(client, true);
              _elevate(model);
              if (!keepOpen) windowManager.minimize();
            });
          }),
        if (state == MustardCmState.active && canElevate)
          MustardCmAction('Allow administrator access', () {
            _guarded(() {
              _elevate(model);
              if (!keepOpen) windowManager.minimize();
            });
          }),
        if (state == MustardCmState.active && client.fromSwitch)
          MustardCmAction('Switch back',
              () => _guarded(() => bind.cmSwitchBack(connId: client.id))),
        if (state == MustardCmState.active &&
            client.type_() == ClientType.file)
          MustardCmAction('Show file transfers',
              () => _guarded(gFFI.chatModel.toggleCMFilePage)),
      ];
      disconnect() => _guarded(() => bind.cmCloseConnection(connId: client.id));
      return Obx(() => MustardConnectionView(
            key: ValueKey(client.id),
            name: client.name,
            peerId: client.peerId,
            state: state,
            canAccept: canAccept,
            abilities: mustardAbilities(client),
            elapsedSeconds: _time.value,
            actions: actions,
            onAccept: () => _guarded(() {
              model.sendLoginResponse(client, true);
              if (!keepOpen) windowManager.minimize();
            }),
            onDecline: disconnect,
            onEnd: disconnect,
            onClose: () => _guarded(_close),
          ));
    });
  }
}
