import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String restaurantId;
  final String restaurantName;

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.quantity == quantity &&
        other.restaurantId == restaurantId &&
        other.restaurantName == restaurantName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      price,
      imageUrl,
      quantity,
      restaurantId,
      restaurantName,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void addItem(CartItem item) {
    final existingIndex =
        state.indexWhere((cartItem) => cartItem.id == item.id);

    if (existingIndex == -1) {
      state = [...state, item.copyWith(quantity: 1)];
      return;
    }

    final existingItem = state[existingIndex];
    state = [
      ...state.sublist(0, existingIndex),
      existingItem.copyWith(quantity: existingItem.quantity + 1),
      ...state.sublist(existingIndex + 1),
    ];
  }

  void incrementQuantity(String itemId) {
    final index = state.indexWhere((cartItem) => cartItem.id == itemId);
    if (index == -1) return;

    final currentItem = state[index];
    state = [
      ...state.sublist(0, index),
      currentItem.copyWith(quantity: currentItem.quantity + 1),
      ...state.sublist(index + 1),
    ];
  }

  void decrementQuantity(String itemId) {
    final index = state.indexWhere((cartItem) => cartItem.id == itemId);
    if (index == -1) return;

    final currentItem = state[index];
    final nextQuantity = currentItem.quantity - 1;

    if (nextQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = [
      ...state.sublist(0, index),
      currentItem.copyWith(quantity: nextQuantity),
      ...state.sublist(index + 1),
    ];
  }

  void removeItem(String itemId) {
    state = state.where((cartItem) => cartItem.id != itemId).toList();
  }

  void clearCart() {
    state = const [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartTotalItemsProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold<int>(0, (total, item) => total + item.quantity);
});

final cartTotalPriceProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );
});
