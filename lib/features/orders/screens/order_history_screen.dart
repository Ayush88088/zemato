import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final ordersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(<Map<String, dynamic>>[]);

  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList());
});

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'placed':
        return Colors.orange;
      case 'processing':
        return cs.primary;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Orders')),
        body: Center(
          child: Text(
            'Please log in to view orders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Could not load orders.'),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final id = (order['id'] as String?) ?? '';
              final shortId = id.isEmpty
                  ? ''
                  : '#${id.substring(0, id.length >= 8 ? 8 : id.length)}';

              final createdAtRaw = order['createdAt'];
              String createdAtText;
              if (createdAtRaw == null) {
                createdAtText = 'Just now';
              } else {
                DateTime dt;
                if (createdAtRaw is Timestamp) {
                  dt = createdAtRaw.toDate();
                } else if (createdAtRaw is DateTime) {
                  dt = createdAtRaw;
                } else {
                  dt = DateTime.tryParse(createdAtRaw.toString()) ??
                      DateTime.now();
                }
                createdAtText = DateFormat('d MMM, h:mm a').format(dt);
              }

              final status = (order['status'] as String?) ?? 'placed';

              final items = (order['items'] as List<dynamic>?) ?? <dynamic>[];
              final totalItems = items.fold<int>(0, (acc, it) {
                final q = (it is Map && it['quantity'] != null)
                    ? (it['quantity'] as num).toInt()
                    : 0;
                return acc + q;
              });

              final totalVal = (order['total'] as num?)?.toDouble() ??
                  (order['subtotal'] as num?)?.toDouble() ??
                  0.0;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  shortId,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Chip(
                                  backgroundColor:
                                      _statusColor(status, colorScheme),
                                  label: Text(
                                    status,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              createdAtText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '$totalItems items',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '₹${totalVal.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
