import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'loading_widgets.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message = 'Something went wrong',
    this.buttonText,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onAction;
  final IconData icon;
  final Widget? customIcon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onAction,
    this.icon = Icons.inbox_outlined,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ??
                Icon(
                  icon,
                  size: 80,
                  color: AppColors.outline,
                ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
            if (onAction != null && buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      message:
          'No internet connection. Please check your network and try again.',
      icon: Icons.wifi_off_outlined,
      buttonText: 'Retry',
      onRetry: onRetry,
    );
  }
}

class NotFoundWidget extends StatelessWidget {
  final String itemName;
  final VoidCallback? onBack;

  const NotFoundWidget({
    super.key,
    this.itemName = 'Item',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: '$itemName Not Found',
      subtitle:
          'The $itemName you\'re looking for doesn\'t exist or has been removed.',
      icon: Icons.search_off_outlined,
      buttonText: 'Go Back',
      onAction: onBack,
    );
  }
}

class ComingSoonWidget extends StatelessWidget {
  final String? featureName;

  const ComingSoonWidget({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: featureName != null ? '$featureName Coming Soon' : 'Coming Soon',
      subtitle: 'This feature is under development. Stay tuned!',
      icon: Icons.construction_outlined,
    );
  }
}

class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onAction;
  final bool showCheckmark;

  const SuccessStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onAction,
    this.showCheckmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showCheckmark) ...[
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
            if (onAction != null && buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PendingStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? customAnimation;

  const PendingStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.customAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customAnimation ?? const AppLoadingIndicator(size: 60),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
