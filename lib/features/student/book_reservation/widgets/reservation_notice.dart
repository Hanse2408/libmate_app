import 'package:flutter/material.dart';

Future<void> showReservationNotice(
  BuildContext context, {
  required String message,
  String title = 'Reservation protected',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Reservation notice',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = Theme.of(dialogContext);
      final colors = theme.colorScheme;
      return PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary.withValues(alpha: 0.18), colors.secondary.withValues(alpha: 0.08)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            tooltip: 'Close notice',
                            iconSize: 19,
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(backgroundColor: colors.surface.withValues(alpha: 0.8)),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 5),
                            ),
                            child: Icon(Icons.lock_outline_rounded, size: 36, color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 30),
                    child: Column(
                      children: [
                        Text(title, textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(message, textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
                        const SizedBox(height: 22),
                        Container(
                          width: 44, height: 4,
                          decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}