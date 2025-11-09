import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';
import 'complaint_detail_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    String newFilter = 'all';
    switch (_tabController.index) {
      case 0:
        newFilter = 'all';
        break;
      case 1:
        newFilter = 'pending';
        break;
      case 2:
        newFilter = 'processing';
        break;
      case 3:
        newFilter = 'resolved';
        break;
      case 4:
        newFilter = 'rejected';
        break;
    }

    if (newFilter != _currentFilter) {
      setState(() {
        _currentFilter = newFilter;
      });
      _loadComplaints();
    }
  }

  Future<void> _loadComplaints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    final token = authProvider.token ?? '';
    if (token.isNotEmpty) {
      await complaintProvider.getMyComplaints(
        token: token,
        status: _currentFilter,
      );
    }
  }

  Future<void> _refreshComplaints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    final token = authProvider.token ?? '';
    if (token.isNotEmpty) {
      await complaintProvider.refresh(token);
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

  Widget _buildComplaintCard(complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                complaintId: complaint.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đơn hàng #${complaint.orderId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(complaint.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          complaint.getStatusEmoji(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          complaint.getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(complaint.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                complaint.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Date + Response count + Images
              Row(
                children: [
                  // Date
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Response count
                  if (complaint.responseCount > 0) ...[
                    Icon(Icons.message, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.responseCount} phản hồi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Image count
                  if (complaint.imageUrls.isNotEmpty) ...[
                    Icon(Icons.image, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.imageUrls.length} ảnh',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
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
        title: const Text('Khiếu nại của tôi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: '⏳ Chờ xử lý'),
            Tab(text: '🔄 Đang xử lý'),
            Tab(text: '✅ Đã giải quyết'),
            Tab(text: '❌ Đã từ chối'),
          ],
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, complaintProvider, child) {
          if (complaintProvider.isLoading && complaintProvider.complaints.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (complaintProvider.error != null) {
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
                    onPressed: _loadComplaints,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (complaintProvider.complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có khiếu nại nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các khiếu nại của bạn sẽ hiển thị ở đây',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshComplaints,
            child: ListView.builder(
              itemCount: complaintProvider.complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaintProvider.complaints[index];
                return _buildComplaintCard(complaint);
              },
            ),
          );
        },
      ),
    );
  }
}
