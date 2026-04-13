import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class BookingChatScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BookingModel booking, String userId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await LocalBookingService.instance.sendBookingMessage(
        bookingId: booking.bookingId,
        senderId: userId,
        message: text,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Chat')),
        body: const EmptyStateWidget(
          title: 'Sign In Required',
          subtitle: 'Please sign in to open booking chat.',
          icon: Icons.lock_outline,
        ),
      );
    }

    return FutureBuilder<BookingModel?>(
      future: LocalBookingService.instance.getBookingById(widget.bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Chat')),
            body: const Center(child: AppLoadingIndicator()),
          );
        }

        final booking = snapshot.data;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Chat')),
            body: const EmptyStateWidget(
              title: 'Booking Not Found',
              subtitle:
                  'This chat is unavailable because the booking was not found.',
              icon: Icons.chat_bubble_outline,
            ),
          );
        }

        final isCustomer = user.uid == booking.customerId;
        final isAssignedProvider =
            booking.providerId != null && user.uid == booking.providerId;

        if (!isCustomer && !isAssignedProvider) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Chat')),
            body: const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle:
                  'Only the booking customer and assigned provider can chat here.',
              icon: Icons.lock_outline,
            ),
          );
        }

        if (booking.providerId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Chat')),
            body: const EmptyStateWidget(
              title: 'Provider Not Assigned',
              subtitle:
                  'Chat will be enabled once a provider accepts your booking.',
              icon: Icons.hourglass_bottom,
            ),
          );
        }

        final peerName = isCustomer
            ? (booking.providerName ?? 'Provider')
            : (booking.customerName ?? 'Customer');

        return Scaffold(
          appBar: AppBar(
            title: Text('Chat with $peerName'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(22),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Booking #${booking.bookingId.substring(0, 8)}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<BookingChatMessage>>(
                  stream: LocalBookingService.instance
                      .watchBookingMessages(booking.bookingId),
                  builder: (context, messagesSnapshot) {
                    final messages =
                        messagesSnapshot.data ?? const <BookingChatMessage>[];

                    LocalBookingService.instance.markMessagesRead(
                      bookingId: booking.bookingId,
                      viewerId: user.uid,
                    );

                    if (messages.isNotEmpty) {
                      _scrollToBottom();
                    }

                    if (messagesSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        messages.isEmpty) {
                      return const Center(child: AppLoadingIndicator());
                    }

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Start the conversation.',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message.senderId == user.uid;
                        return _ChatBubble(message: message, isMine: isMine);
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(booking, user.uid),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending
                            ? null
                            : () => _sendMessage(booking, user.uid),
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final BookingChatMessage message;
  final bool isMine;

  const _ChatBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.messageText),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
