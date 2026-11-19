// lib/widgets/order_chat_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/ably_service.dart';
import '../utils/app_config.dart';

class OrderChatSheet extends StatefulWidget {
  final int orderId;
  final String hotelName;
  final bool isDriverAssigned;

  const OrderChatSheet({
    super.key,
    required this.orderId,
    required this.hotelName,
    required this.isDriverAssigned,
  });

  static Future<void> show(
    BuildContext context, {
    required int orderId,
    required String hotelName,
    required bool isDriverAssigned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: OrderChatSheet(
          orderId: orderId,
          hotelName: hotelName,
          isDriverAssigned: isDriverAssigned,
        ),
      ),
    );
  }

  @override
  State<OrderChatSheet> createState() => _OrderChatSheetState();
}

class _OrderChatSheetState extends State<OrderChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<OrderChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isChatEnabled = true;
  StreamSubscription? _ablySub;

  @override
  void initState() {
    super.initState();
    _isChatEnabled = !widget.isDriverAssigned;
    _fetchMessages();
    _initAblyListener();
  }

  @override
  void dispose() {
    _ablySub?.cancel();
    AblyService.instance.unsubscribeFromChannel(kOrderChatChannel(widget.orderId));
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final result = await ChatService.instance.getMessages(widget.orderId);
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
      ChatService.instance.markAsRead(widget.orderId);
      _scrollToBottom();
    }
  }

  void _initAblyListener() {
    _ablySub = AblyService.instance.subscribe(kOrderChatChannel(widget.orderId)).listen((msg) {
      if (!mounted) return;
      final event = msg['event'] as String?;
      final data = msg['data'];

      if (event == 'CHAT_MESSAGE' && data != null) {
        final newMsg = OrderChatMessage.fromJson(Map<String, dynamic>.from(data));
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

          if (newMsg.senderType == 'vendor') {
            ChatService.instance.markAsRead(widget.orderId);
          }
        }
      } else if (event == 'CHAT_READ_RECEIPT') {
        final readOrderId = int.tryParse(data?['order_id']?.toString() ?? '0');
        if (readOrderId == null || readOrderId == widget.orderId) {
          setState(() {
            _messages = _messages.map((m) {
              if (m.senderType == 'customer') {
                return OrderChatMessage(
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

    final success = await ChatService.instance.sendMessage(widget.orderId, text);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (success) {
      _fetchMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
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
                        color: const Color(0xFFF58220).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Color(0xFFF58220), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotelName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #${widget.orderId} • Pre-pickup Chat',
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
                      'Driver assigned. Direct chat with restaurant is now closed for this order.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // Chat Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)))
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
                              'Send a message to contact ${widget.hotelName}',
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
                          final isCustomer = msg.senderType == 'customer';
                          final timeStr = "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}";

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isCustomer) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFFF58220).withOpacity(0.15),
                                    child: const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFFF58220)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isCustomer ? const Color(0xFFF58220) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isCustomer ? 16 : 4),
                                      bottomRight: Radius.circular(isCustomer ? 4 : 16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          color: isCustomer ? Colors.white : const Color(0xFF1A1A2E),
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
                                              color: isCustomer ? Colors.white70 : Colors.grey.shade600,
                                            ),
                                          ),
                                          if (isCustomer) ...[
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
                        hintText: _isChatEnabled ? 'Type a message to restaurant...' : 'Chat disabled (Driver assigned)',
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
                    color: _isChatEnabled ? const Color(0xFFF58220) : Colors.grey.shade300,
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
