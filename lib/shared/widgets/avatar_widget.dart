import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials = Helpers.getInitials(name);
    final bgColor = Helpers.getAvatarColor(name);

    Widget? imageChild;
    if (hasImage) {
      final value = imageUrl!.trim();
      if (value.startsWith('data:image')) {
        final commaIndex = value.indexOf(',');
        if (commaIndex > 0 && commaIndex < value.length - 1) {
          try {
            imageChild = Image.memory(
              base64Decode(value.substring(commaIndex + 1)),
              fit: BoxFit.cover,
            );
          } catch (_) {
            imageChild = null;
          }
        }
      } else if (value.startsWith('http://') || value.startsWith('https://')) {
        imageChild = CachedNetworkImage(
          imageUrl: value,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallback(initials),
        );
      }
    }

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageChild != null ? null : bgColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: imageChild != null
          ? ClipOval(
              child: imageChild,
            )
          : _buildFallback(initials),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final int? notificationCount;
  final VoidCallback? onTap;

  const AvatarWithBadge({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.isOnline = false,
    this.notificationCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        UserAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        if (notificationCount != null && notificationCount! > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  notificationCount! > 9 ? '9+' : notificationCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProviderAvatarRow extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double? rating;
  final int? reviewCount;
  final String? subtitle;
  final double avatarSize;
  final VoidCallback? onTap;

  const ProviderAvatarRow({
    super.key,
    this.imageUrl,
    required this.name,
    this.rating,
    this.reviewCount,
    this.subtitle,
    this.avatarSize = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: imageUrl,
              name: name,
              size: avatarSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  if (rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
