import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';

final restaurantProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, restaurantId) async {
    final restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .get();

    if (!restaurantDoc.exists) {
      return null;
    }

    final data = restaurantDoc.data() ?? <String, dynamic>{};
    return <String, dynamic>{'id': restaurantDoc.id, ...data};
  },
);

final menuProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, restaurantId) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return <String, dynamic>{'id': doc.id, ...data};
            }).toList());
  },
);

class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final restaurantAsync = ref.watch(restaurantProvider(restaurantId));
    final menuAsync = ref.watch(menuProvider(restaurantId));
    final cartItemCount = ref.watch(cartTotalItemsProvider);
    final cartTotalPrice = ref.watch(cartTotalPriceProvider);

    return restaurantAsync.when(
      data: (restaurant) {
        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Restaurant not found.'),
            ),
          );
        }

        final restaurantName = (restaurant['name'] as String?) ?? 'Restaurant';
        final imageUrl = (restaurant['imageUrl'] as String?) ?? '';
        final cuisine = (restaurant['cuisine'] as String?) ?? 'Various';
        final rating = restaurant['rating'] ?? 4.5;
        final deliveryTimeMins = restaurant['deliveryTimeMins'] ?? 30;

        final groupedMenuItems = <String, List<Map<String, dynamic>>>{};

        for (final menuItem in menuAsync.value ?? <Map<String, dynamic>>[]) {
          final category = (menuItem['category'] as String?) ?? 'Other';
          groupedMenuItems.putIfAbsent(
              category, () => <Map<String, dynamic>>[]);
          groupedMenuItems[category]!.add(menuItem);
        }

        final categories = groupedMenuItems.keys.toList();

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 220,
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                    title: Text(restaurantName),
                    flexibleSpace: FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cuisine,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(rating.toString()),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$deliveryTimeMins mins',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  menuAsync.when(
                    data: (menuItems) {
                      if (menuItems.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text('No menu items available.'),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final category = categories[index];
                            final items = groupedMenuItems[category] ??
                                <Map<String, dynamic>>[];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    category,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...items.map((item) {
                                    final isVeg = item['isVeg'] == true;
                                    final name =
                                        (item['name'] as String?) ?? 'Item';
                                    final description =
                                        (item['description'] as String?) ??
                                            'Freshly prepared';
                                    final price =
                                        (item['price'] as num?)?.toDouble() ??
                                            0.0;
                                    final thumbnailUrl =
                                        (item['imageUrl'] as String?) ?? '';

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            margin: const EdgeInsets.only(
                                              top: 6,
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isVeg
                                                    ? Colors.green
                                                    : Colors.red,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: isVeg
                                                      ? Colors.green
                                                      : Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: SizedBox(
                                              width: 64,
                                              height: 64,
                                              child: CachedNetworkImage(
                                                imageUrl: thumbnailUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '₹${price.toString()}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                          const SizedBox(width: 10),
                                          OutlinedButton(
                                            onPressed: () {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .addItem(
                                                    CartItem(
                                                      id: item['id'] as String,
                                                      name: name,
                                                      price: price,
                                                      imageUrl: thumbnailUrl,
                                                      quantity: 1,
                                                      restaurantId:
                                                          restaurantId,
                                                      restaurantName:
                                                          restaurantName,
                                                    ),
                                                  );
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('Added to cart'),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: const Text('Add'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                          childCount: categories.length,
                        ),
                      );
                    },
                    error: (error, stackTrace) => SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            const Text('Something went wrong'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                ref.invalidate(menuProvider(restaurantId));
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ],
              ),
              if (cartItemCount > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$cartItemCount items | ₹${cartTotalPrice.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: const Text('View Cart'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              const Text('Something went wrong'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(restaurantProvider(restaurantId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
