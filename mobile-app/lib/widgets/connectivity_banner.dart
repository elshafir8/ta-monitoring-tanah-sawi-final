import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _checkInitialStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(results);
    } catch (_) {
      // Jika terjadi error saat membaca status, biarkan default false
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool disconnected = results.isEmpty ||
        results.contains(ConnectivityResult.none) ||
        !results.any((r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn);

    if (mounted && _isOffline != disconnected) {
      setState(() {
        _isOffline = disconnected;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Material(
            color: const Color(0xFFD32F2F),
            elevation: 4,
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: const [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tidak ada koneksi internet. Data yang ditampilkan adalah data terakhir yang tersimpan.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          crossFadeState:
              _isOffline ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
