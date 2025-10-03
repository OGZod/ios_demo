import 'package:flutter/material.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

class DndService {
  final DoNotDisturbPlugin _dndPlugin = DoNotDisturbPlugin();

  /// Check if Do Not Disturb (DND) mode is currently enabled
  Future<bool> isDndEnabled() async {
    try {
      return await _dndPlugin.isDndEnabled();
    } catch (e) {
      debugPrint('Error checking DND status: $e');
      return false;
    }
  }

  /// Get the current DND status/filter level
  Future<InterruptionFilter> getDndStatus() async {
    try {
      return await _dndPlugin.getDNDStatus();
    } catch (e) {
      debugPrint('Error getting DND status: $e');
      return InterruptionFilter.unknown;
    }
  }

  /// Check if the app has permission to modify DND settings
  Future<bool> hasNotificationPolicyAccess() async {
    try {
      return await _dndPlugin.isNotificationPolicyAccessGranted();
    } catch (e) {
      debugPrint('Error checking notification policy access: $e');
      return false;
    }
  }

  /// Open the system DND settings
  Future<void> openDndSettings() async {
    try {
      await _dndPlugin.openDndSettings();
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
    }
  }

  /// Open notification policy access settings to request permission
  Future<void> openNotificationPolicyAccessSettings() async {
    try {
      await _dndPlugin.openNotificationPolicyAccessSettings();
    } catch (e) {
      debugPrint('Error opening notification policy access settings: $e');
    }
  }

  /// Set DND mode to a specific filter level
  Future<bool> setInterruptionFilter(InterruptionFilter filter) async {
    try {
      await _dndPlugin.setInterruptionFilter(filter);
      return true;
    } catch (e) {
      debugPrint('Error setting interruption filter: $e');
      return false;
    }
  }

  /// Enable DND mode (allows only alarms)
  Future<bool> enableDnd() async {
    return await setInterruptionFilter(InterruptionFilter.alarms);
  }

  /// Disable DND mode (allow all notifications)
  Future<bool> disableDnd() async {
    return await setInterruptionFilter(InterruptionFilter.all);
  }

  /// Toggle DND mode on/off
  /// Returns the new state: true if DND was enabled, false if it was disabled
  Future<bool> toggleDnd() async {
    final bool currentlyEnabled = await isDndEnabled();

    if (currentlyEnabled) {
      await disableDnd();
      return false;
    } else {
      await enableDnd();
      return true;
    }
  }

  /// Helper method to ensure we have permission before trying to modify DND
  /// Returns true if we have permission, false otherwise
  Future<bool> ensurePermission(BuildContext context) async {
    final bool hasAccess = await hasNotificationPolicyAccess();

    if (!hasAccess && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission needed to modify Do Not Disturb settings'),
        ),
      );
      await Future.delayed(
        Duration(seconds: 3),
        () async => await openNotificationPolicyAccessSettings(),
      );
      return false;
    }

    return true;
  }
}
