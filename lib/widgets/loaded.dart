import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import 'action_button.dart';

/// Shows what [load] brings, a spinner while it comes, and a way to try again when it fails.
///
/// [pending] frames the spinner or the failure, so a screen keeps its header and tab bar while
/// its data is on the way.
class Loaded<T> extends StatefulWidget {
  const Loaded({super.key, required this.load, required this.builder, this.pending});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(Widget status)? pending;

  @override
  State<Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends State<Loaded<T>> {
  // Kept by hand rather than with a FutureBuilder, which holds on to the previous error while a
  // retry is under way and would leave the failure on screen instead of the spinner.
  _Phase _phase = _Phase.loading;
  late T _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.loaded) return widget.builder(context, _data);
    final status = _phase == _Phase.failed ? _LoadFailure(onRetry: _retry) : const _Loading();
    return widget.pending?.call(status) ?? status;
  }

  Future<void> _load() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _phase = _Phase.loaded;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  void _retry() {
    setState(() => _phase = _Phase.loading);
    _load();
  }
}

enum _Phase { loading, failed, loaded }

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppConstants.loadFailed, textAlign: TextAlign.center, style: AppText.footnote),
          const SizedBox(height: 16),
          ActionButton.tinted(label: AppConstants.btnRetry, onPressed: onRetry),
        ],
      ),
    );
  }
}
