// lib/widgets/vendor_order_chat_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/vendor_chat_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';

class VendorOrderChatSheet extends StatefulWidget {
  final int orderId;
  final String customerName;
  final bool isDriverAssigned;

  const VendorOrderChatSheet({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.isDriverAssigned,
  });

  static Future<void> show(
    BuildContext context, {
    required int orderId,
    required String customerName,
    required bool isDriverAssigned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: VendorOrderChatSheet(
          orderId: orderId,
          customerName: customerName,
          isDriverAssigned: isDriverAssigned,
        ),
      ),
    );
  }

  @override
  State<VendorOrderChatSheet> createState() => _VendorOrderChatSheetState();
}

class _VendorOrderChatSheetState extends State<VendorOrderChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<VendorChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isChatEnabled = true;
  StreamSubscription? _ablySub;

  @override
  void initState() {
    super.initState();
    _isChatEnabled = !widget.isDriverAssigned;
    _fetchMessages();
    WebSocketService.instance.subscribeToChannel(kOrderChatChannel(widget.orderId));
    _initAblyListener();
  }

  @override
  void dispose() {
    _ablySub?.cancel();
    WebSocketService.instance.unsubscribeFromChannel(kOrderChatChannel(widget.orderId));
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final result = await VendorChatService.instance.getMessages(widget.orderId);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _messages = result.messages;
        if (!result.isChatEnabled) {
          _isChatEnabled = false;
        }
      }
    });

    if (result.success) {
      VendorChatService.instance.markAsRead(widget.orderId);
      _scrollToBottom();
    }
  }

  void _initAblyListener() {
    _ablySub = WebSocketService.instance.messages.listen((msg) {
      if (!mounted) return;
      final event = msg['event'] as String?;
      final data = msg['data'];

      if (event == 'CHAT_MESSAGE' && data != null) {
        final newMsg = VendorChatMessage.fromJson(Map<String, dynamic>.from(data));
        if (newMsg.orderId == widget.orderId) {
          setState(() {
            final existingIdx = _messages.indexWhere((m) => m.id == newMsg.id);
            if (existingIdx >= 0) {
              _messages[existingIdx] = newMsg;
            } else {
              _messages.add(newMsg);
            }
          });
          _scrollToBottom();

          if (newMsg.senderType == 'customer') {
            VendorChatService.instance.markAsRead(widget.orderId);
          }
        }
      } else if (event == 'CHAT_READ_RECEIPT') {
        final orderId = int.tryParse((data is Map ? data['order_id'] : null)?.toString() ?? '0');
        if (orderId == 0 || orderId == widget.orderId) {
          setState(() {
            _messages = _messages.map((m) {
              if (m.senderType == 'vendor') {
                return VendorChatMessage(
                  id: m.id,
                  orderId: m.orderId,
                  senderType: m.senderType,
                  senderId: m.senderId,
                  message: m.message,
                  isRead: true,
                  createdAt: m.createdAt,
                );
              }
              return m;
            }).toList();
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || !_isChatEnabled) return;

    _messageController.clear();
    setState(() => _isSending = true);

    final success = await VendorChatService.instance.sendMessage(widget.orderId, text);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (success) {
      _fetchMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${widget.customerName}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #${widget.orderId} • Direct Customer Chat',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Disabled notice banner if driver is assigned
          if (!_isChatEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver assigned. Direct chat with customer is now closed for this order.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // Chat Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reply to ${widget.customerName}\'s inquiries here',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isVendor = msg.senderType == 'vendor';
                          final timeStr = "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}";

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isVendor ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isVendor) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isVendor ? AppColors.primary : Colors.grey.shade100,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isVendor ? 16 : 4),
                                      bottomRight: Radius.circular(isVendor ? 4 : 16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          color: isVendor ? Colors.white : AppColors.ink,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isVendor ? Colors.white70 : Colors.grey.shade600,
                                            ),
                                          ),
                                          if (isVendor) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                              size: 14,
                                              color: msg.isRead ? Colors.lightGreenAccent : Colors.white70,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _isChatEnabled,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isChatEnabled ? 'Type a reply to customer...' : 'Chat disabled (Driver assigned)',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _isChatEnabled ? AppColors.primary : Colors.grey.shade300,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isChatEnabled ? _handleSend : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
