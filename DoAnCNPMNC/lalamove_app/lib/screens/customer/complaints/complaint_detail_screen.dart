import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComplaintDetail();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaintDetail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    final token = authProvider.token ?? '';
    if (token.isNotEmpty) {
      await complaintProvider.getComplaintDetail(
        complaintId: widget.complaintId,
        token: token,
      );
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    final token = authProvider.token ?? '';
    final success = await complaintProvider.sendReply(
      complaintId: widget.complaintId,
      message: _replyController.text.trim(),
      token: token,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      _replyController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi phản hồi'),
          backgroundColor: Colors.green,
        ),
      );
      // Scroll to bottom to show new message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            complaintProvider.error ?? 'Không thể gửi phản hồi',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullImage(context, imageUrls, index),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, List<String> images, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: index),
              itemCount: images.length,
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  child: Image.network(
                    images[i],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(response, bool isCurrentUser) {
    final isAdmin = response.isAdmin;
    final alignRight = !isAdmin && isCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '👨‍💼 Admin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                response.responderName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAdmin
                  ? Colors.blue[50]
                  : (alignRight ? AppColors.primary : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(alignRight ? 16 : 4),
                bottomRight: Radius.circular(alignRight ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: alignRight && !isAdmin ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(response.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: alignRight && !isAdmin
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khiếu nại'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaintDetail,
          ),
        ],
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, complaintProvider, child) {
          if (complaintProvider.isLoading &&
              complaintProvider.currentComplaint == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (complaintProvider.error != null &&
              complaintProvider.currentComplaint == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    complaintProvider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadComplaintDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final complaint = complaintProvider.currentComplaint;
          if (complaint == null) return const SizedBox.shrink();

          final authProvider = Provider.of<AuthProvider>(context);
          final isCurrentUser = authProvider.user?.id == complaint.customerId;

          return Column(
            children: [
              // Complaint info section
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(complaint.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(complaint.status),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    complaint.getStatusEmoji(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    complaint.getStatusText(),
                                    style: TextStyle(
                                      color: _getStatusColor(complaint.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Order info
                            if (complaint.order != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📦 Đơn hàng: ${complaint.order!.orderCode}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '📍 Từ: ${complaint.order!.pickupAddress}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🏠 Đến: ${complaint.order!.deliveryAddress}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Description
                            Text(
                              'Mô tả:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complaint.description,
                              style: const TextStyle(fontSize: 14),
                            ),

                            // Images
                            _buildImageGallery(complaint.imageUrls),

                            // Created date
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tạo lúc ${_formatTime(complaint.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Conversation section
                      if (complaint.responses != null &&
                          complaint.responses!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '💬 Cuộc trò chuyện (${complaint.responses!.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...complaint.responses!.map(
                          (response) =>
                              _buildMessageBubble(response, isCurrentUser),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Chưa có phản hồi nào',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 80), // Space for reply box
                    ],
                  ),
                ),
              ),

              // Reply input box (only if not rejected)
              if (complaint.status != 'rejected')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Nhập phản hồi...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : IconButton(
                              onPressed: _sendReply,
                              icon: const Icon(Icons.send),
                              color: AppColors.primary,
                              iconSize: 28,
                            ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
