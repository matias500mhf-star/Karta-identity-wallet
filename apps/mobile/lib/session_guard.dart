import 'dart:async';

import 'package:flutter/material.dart';

import 'brand_theme.dart';

class SessionSecurity {
  static final locked = ValueNotifier<bool>(false);
  static bool active = false;
  static void unlock() {
    active = true;
    locked.value = false;
  }

  static void lock() {
    if (active) locked.value = true;
  }

  static void reset() {
    active = false;
    locked.value = false;
  }
}

class SessionGuard extends StatefulWidget {
  const SessionGuard({
    super.key,
    required this.child,
    required this.lockPageBuilder,
  });
  final Widget child;
  final Widget Function(VoidCallback) lockPageBuilder;
  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  Timer? timer;
  bool obscured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionSecurity.locked.addListener(_changed);
    _touch();
  }

  void _changed() {
    _touch();
    if (mounted) setState(() {});
  }

  void _touch() {
    timer?.cancel();
    if (!SessionSecurity.locked.value)
      timer = Timer(const Duration(minutes: 5), SessionSecurity.lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden)
      SessionSecurity.lock();
    if (mounted) setState(() => obscured = state != AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      _touch();
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    SessionSecurity.locked.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _touch(),
    onPointerMove: (_) => _touch(),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: SessionSecurity.locked.value || obscured,
          child: IgnorePointer(
            ignoring: SessionSecurity.locked.value || obscured,
            child: widget.child,
          ),
        ),
        if (SessionSecurity.locked.value)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: ScaffoldMessenger(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) =>
                        widget.lockPageBuilder(SessionSecurity.unlock),
                  ),
                ),
              ),
            ),
          ),
        if (obscured && SessionSecurity.active)
          const Positioned.fill(
            child: ColoredBox(
              color: HmatiasBrand.navy,
              child: Center(
                child: Icon(Icons.lock_outline, size: 56, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );
}
