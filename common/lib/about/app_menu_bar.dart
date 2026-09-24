// From jejezz/application-release-templates common/ @ conventions-v1.
//
// macOS 앱 메뉴의 "About <앱>"이 앱 바의 정보 버튼과 같은 대화상자를 열게
// 한다 (conventions/about-dialog.md §1). macOS가 아니면 child를 그대로 둔다.
// PlatformMenuBar는 기본 메뉴를 대체하므로 숨기기·종료 같은 표준 항목도
// 여기서 다시 넣는다.

import 'dart:io';

import 'package:flutter/material.dart';

import '../app_identity.dart';
import '../l10n/app_localizations.dart';

class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key, required this.onAbout, required this.child});

  /// 보통 `() => showAppAboutDialog(navigatorKey.currentContext!, …)`.
  final VoidCallback onAbout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) return child;
    final l10n = AppLocalizations.of(context);
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: AppIdentity.displayName,
          menus: [
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(label: l10n.aboutMenuItem(AppIdentity.displayName), onSelected: onAbout),
            ]),
            const PlatformMenuItemGroup(members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.servicesSubmenu),
            ]),
            const PlatformMenuItemGroup(members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hideOtherApplications),
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.showAllApplications),
            ]),
            const PlatformMenuItemGroup(members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
            ]),
          ],
        ),
        const PlatformMenu(label: 'Window', menus: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.minimizeWindow),
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.zoomWindow),
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.toggleFullScreen),
        ]),
      ],
      child: child,
    );
  }
}
