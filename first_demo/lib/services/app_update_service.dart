import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Production-ready service managing Google Play In-App Updates for the customer app.
///
/// Features:
/// 1. Initiates the Google Play native flexible update bottom sheet.
/// 2. If Google Play native in-app sheet is blocked by preconditions or fails,
///    falls back gracefully to an in-app Update Dialog pointing directly to Google Play Store.
/// 3. While downloading in background, users continue interacting with the app.
/// 4. Once download finishes, displays a SnackBar to trigger [completeFlexibleUpdate].
/// 5. Automatically detects if an update completed downloading when the app resumes.
class AppUpdateService with WidgetsBindingObserver {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _packageName = 'com.zenqube.hungrilyfoods';

  bool _initialized = false;
  bool _isChecking = false;
  bool _isUpdateInProgress = false;
  bool _hasPromptedThisSession = false;
  AppUpdateInfo? _updateInfo;
  StreamSubscription<InstallStatus>? _installStatusSubscription;

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Exposes current cached update metadata.
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Whether an update check is currently active.
  bool get isChecking => _isChecking;

  /// Whether a flexible update download is currently active.
  bool get isUpdateInProgress => _isUpdateInProgress;

  /// Resolves the current active BuildContext from the root navigator.
  BuildContext? get _activeContext {
    final ctx = _navigatorKey?.currentContext;
    if (ctx != null && ctx.mounted) {
      return ctx;
    }
    return null;
  }

  /// Initializes the service and registers the lifecycle observer.
  /// Pass the application's root [navigatorKey] to allow global UI alerts.
  void initialize({GlobalKey<NavigatorState>? navigatorKey}) {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Cleans up subscriptions and observers.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelInstallSubscription();
    _initialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusOnResume();
    }
  }

  /// On resume, check if a flexible update finished downloading in the background.
  Future<void> _checkStatusOnResume() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_isChecking) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;
      if (info.installStatus == InstallStatus.downloaded) {
        _notifyUpdateDownloaded();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Resume check error: $e');
      }
    }
  }

  /// Opens the app's Google Play Store listing.
  static Future<void> openPlayStore() async {
    final marketUri = Uri.parse('market://details?id=$_packageName');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$_packageName');
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Checks Google Play for an available update.
  ///
  /// - [showFeedbackOnNoUpdate]: If true, displays feedback when already on the latest version.
  /// - [delayMs]: Optional delay in milliseconds to let the native activity gain foreground focus.
  Future<void> checkForUpdate({
    bool showFeedbackOnNoUpdate = false,
    int delayMs = 1500,
  }) async {
    // In-App Updates are only supported on Android. Gracefully no-op on other platforms.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] In-app updates are only supported on Android devices.');
      }
      return;
    }

    if (_isChecking || _isUpdateInProgress) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Update check or download already in progress.');
      }
      return;
    }

    _isChecking = true;

    // Small delay on app startup so native Android activity is completely in foreground
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    try {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Checking for updates on Google Play...');
      }

      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;

      if (kDebugMode) {
        debugPrint(
          '[AppUpdateService] Check result: availability=${info.updateAvailability}, '
          'flexibleAllowed=${info.flexibleUpdateAllowed}, '
          'immediateAllowed=${info.immediateUpdateAllowed}, '
          'availableVersionCode=${info.availableVersionCode}, '
          'installStatus=${info.installStatus}',
        );
      }

      // 1. If an update has already been downloaded, prompt user to restart
      if (info.installStatus == InstallStatus.downloaded) {
        _notifyUpdateDownloaded();
        return;
      }

      // 2. If a new version is available on Google Play
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        bool flowStarted = false;

        if (info.flexibleUpdateAllowed) {
          if (!_hasPromptedThisSession || showFeedbackOnNoUpdate) {
            _hasPromptedThisSession = true;
            flowStarted = await _startFlexibleUpdateFlow();
          } else {
            flowStarted = true;
          }
        } else if (info.immediateUpdateAllowed) {
          try {
            await InAppUpdate.performImmediateUpdate();
            flowStarted = true;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[AppUpdateService] Immediate update failed: $e');
            }
            flowStarted = false;
          }
        }

        // 3. Fallback: If Google Play native in-app sheet was not allowed or failed,
        // present our in-app Update dialog so the user can update via Play Store.
        if (!flowStarted && (!_hasPromptedThisSession || showFeedbackOnNoUpdate)) {
          _hasPromptedThisSession = true;
          _showFallbackUpdateDialog();
        }
      } else {
        if (showFeedbackOnNoUpdate) {
          _showFeedback(message: 'Hungrily Foods is up to date!');
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Google Play PlatformException: [${e.code}] ${e.message}');
      }
      if (showFeedbackOnNoUpdate) {
        _showFeedback(
          message: 'Unable to check for updates: ${e.message ?? e.code}',
          isError: true,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Unexpected error during update check: $e');
      }
      if (showFeedbackOnNoUpdate) {
        _showFeedback(
          message: 'Unable to check for updates.',
          isError: true,
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Starts the Google Play flexible update bottom-sheet flow and monitors download events.
  Future<bool> _startFlexibleUpdateFlow() async {
    _isUpdateInProgress = true;
    _listenToInstallStatus();

    try {
      final result = await InAppUpdate.startFlexibleUpdate();

      switch (result) {
        case AppUpdateResult.success:
          if (kDebugMode) {
            debugPrint('[AppUpdateService] User accepted update. Background download initiated.');
          }
          return true;
        case AppUpdateResult.userDeniedUpdate:
          if (kDebugMode) {
            debugPrint('[AppUpdateService] User declined the update prompt.');
          }
          _isUpdateInProgress = false;
          _cancelInstallSubscription();
          return true;
        case AppUpdateResult.inAppUpdateFailed:
          if (kDebugMode) {
            debugPrint('[AppUpdateService] In-app update failed to initiate.');
          }
          _isUpdateInProgress = false;
          _cancelInstallSubscription();
          return false;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] PlatformException starting flexible update: $e');
      }
      _isUpdateInProgress = false;
      _cancelInstallSubscription();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Exception starting flexible update: $e');
      }
      _isUpdateInProgress = false;
      _cancelInstallSubscription();
      return false;
    }
  }

  /// Listens to Google Play download progress events.
  void _listenToInstallStatus() {
    _cancelInstallSubscription();

    _installStatusSubscription = InAppUpdate.installUpdateListener.listen(
      (InstallStatus status) {
        if (kDebugMode) {
          debugPrint('[AppUpdateService] Play Core InstallStatus event: $status');
        }

        switch (status) {
          case InstallStatus.downloading:
            break;
          case InstallStatus.downloaded:
            _isUpdateInProgress = false;
            _cancelInstallSubscription();
            _notifyUpdateDownloaded();
            break;
          case InstallStatus.failed:
            _isUpdateInProgress = false;
            _cancelInstallSubscription();
            if (kDebugMode) {
              debugPrint('[AppUpdateService] Flexible update download failed.');
            }
            break;
          case InstallStatus.canceled:
            _isUpdateInProgress = false;
            _cancelInstallSubscription();
            if (kDebugMode) {
              debugPrint('[AppUpdateService] Flexible update download canceled.');
            }
            break;
          default:
            break;
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[AppUpdateService] Error on installUpdateListener stream: $error');
        }
        _isUpdateInProgress = false;
        _cancelInstallSubscription();
      },
    );
  }

  void _cancelInstallSubscription() {
    _installStatusSubscription?.cancel();
    _installStatusSubscription = null;
  }

  /// Displays a SnackBar informing the user that the update has downloaded and is ready to install.
  void _notifyUpdateDownloaded() {
    final ctx = _activeContext;
    if (ctx == null) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Cannot show update SnackBar: BuildContext is null.');
      }
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'An update has been downloaded!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'RESTART',
          textColor: const Color(0xFFF07070),
          onPressed: () {
            completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  /// Fallback dialog shown when Google Play's native in-app sheet is not permitted
  /// by Play Core preconditions or fails to show.
  void _showFallbackUpdateDialog() {
    final ctx = _activeContext;
    if (ctx == null) return;

    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.system_update_rounded, color: Color(0xFFF07070), size: 26),
              SizedBox(width: 10),
              Text(
                'Update Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'A newer version of Hungrily Foods is available on Google Play. Please update to continue enjoying the latest features and bug fixes.',
            style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Later', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF07070),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                openPlayStore();
              },
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  /// Completes the flexible update and triggers the native restart/installation flow.
  Future<void> completeFlexibleUpdate() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Calling completeFlexibleUpdate()...');
      }
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Failed to complete flexible update: $e');
      }
      _showFeedback(
        message: 'Failed to restart and install update. Please try again.',
        isError: true,
      );
    }
  }

  void _showFeedback({
    required String message,
    bool isError = false,
  }) {
    final ctx = _activeContext;
    if (ctx == null) return;

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
