import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/screens/order_history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zemato/features/restaurant/screens/restaurant_detail_screen.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final restaurantsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return <String, dynamic>{'id': document.id, ...data};
          }).toList());
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static List<Map<String, dynamic>> _applyCategoryFilter(
    List<Map<String, dynamic>> restaurants,
    String selectedCategory,
  ) {
    if (selectedCategory == 'All') {
      return restaurants;
    }

    final targetCategory = selectedCategory.toLowerCase();
    return restaurants.where((restaurant) {
      final category = (restaurant['category'] ?? '').toString().toLowerCase();
      final cuisine = (restaurant['cuisine'] ?? '').toString().toLowerCase();
      return category == targetCategory || cuisine.contains(targetCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categories = <String>[
      'All',
      'North Indian',
      'Japanese',
      'Fast Food',
      'Desserts',
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deliver to: Lucknow',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        );
                      },
                      tooltip: 'Orders',
                      icon: Icon(
                        Icons.receipt_long_outlined,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      tooltip: 'Profile',
                      icon: Icon(
                        Icons.person_outline,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      tooltip: 'Search',
                      icon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            category;
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(restaurantsProvider);
                  },
                  child: ref.watch(restaurantsProvider).when(
                        loading: () => _buildShimmerList(colorScheme),
                        error: (error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Something went wrong',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(restaurantsProvider);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (restaurants) {
                          final filteredRestaurants = _applyCategoryFilter(
                            restaurants,
                            selectedCategory,
                          );

                          if (filteredRestaurants.isEmpty) {
                            return Center(
                              child: Text(
                                'No restaurants available right now.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: filteredRestaurants.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final restaurant = filteredRestaurants[index];
                              final imageUrl =
                                  restaurant['imageUrl'] as String? ?? '';
                              final name =
                                  restaurant['name'] as String? ?? 'Restaurant';
                              final cuisine =
                                  restaurant['cuisine'] as String? ?? 'Various';
                              final rating = restaurant['rating'] ?? 4.5;
                              final deliveryTimeMins =
                                  restaurant['deliveryTimeMins'] ?? 25;

                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => RestaurantDetailScreen(
                                          restaurantId:
                                              restaurant['id'] as String,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: SizedBox(
                                            width: 110,
                                            height: 110,
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                cuisine,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rating.toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    color: colorScheme.primary,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$deliveryTimeMins mins',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(ColorScheme colorScheme) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surfaceContainerLow,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}
