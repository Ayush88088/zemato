import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../../orders/screens/order_confirmation_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool isPlacingOrder = false;
  final TextEditingController deliveryAddressController = TextEditingController();

  @override
  void dispose() {
    deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalPriceProvider);
    final deliveryFee = 30.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: cartItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          return Card(
                            elevation: 1,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.price.toStringAsFixed(0)} each',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .decrementQuantity(item.id);
                                        },
                                        icon: const Icon(Icons.remove),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      SizedBox(
                                        width: 28,
                                        child: Center(
                                          child: Text(
                                            item.quantity.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .incrementQuantity(item.id);
                                        },
                                        icon: const Icon(Icons.add),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: deliveryAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Subtotal',
                              amount: '₹${subtotal.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Delivery fee',
                              amount: '₹${deliveryFee.toStringAsFixed(0)}',
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Total',
                              amount: '₹${total.toStringAsFixed(0)}',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty || isPlacingOrder
                            ? null
                            : () async {
                                if (deliveryAddressController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a delivery address'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isPlacingOrder = true);

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  setState(() => isPlacingOrder = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please log in')),
                                  );
                                  return;
                                }

                                final items = cartItems
                                    .map((i) => {
                                          'id': i.id,
                                          'name': i.name,
                                          'price': i.price,
                                          'quantity': i.quantity,
                                          'restaurantId': i.restaurantId,
                                          'restaurantName': i.restaurantName,
                                        })
                                    .toList();

                                final subtotalVal =
                                    ref.read(cartTotalPriceProvider);
                                final orderData = {
                                  'userId': user.uid,
                                  'items': items,
                                  'subtotal': subtotalVal,
                                  'deliveryFee': deliveryFee,
                                  'total': subtotalVal + deliveryFee,
                                  'deliveryAddress': deliveryAddressController.text.trim(),
                                  'driverId': null,
                                  'status': 'placed',
                                  'createdAt': FieldValue.serverTimestamp(),
                                };

                                try {
                                  final docRef = await FirebaseFirestore
                                      .instance
                                      .collection('orders')
                                      .add(orderData);

                                  ref.read(cartProvider.notifier).clearCart();

                                  if (!mounted) return;
                                  setState(() => isPlacingOrder = false);

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => OrderConfirmationScreen(
                                          orderId: docRef.id,
                                        ),
                                      ),
                                    );
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => isPlacingOrder = false);

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isPlacingOrder
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Place Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final String amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: isTotal ? colorScheme.primary : colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}