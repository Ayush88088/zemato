// seed.js
// Seeds sample restaurant + menu data into Firestore for the Zemato app.

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

const restaurants = [
  {
    id: 'punjabi-tadka',
    data: {
      name: 'Punjabi Tadka',
      cuisine: 'North Indian',
      rating: 4.3,
      imageUrl: 'https://picsum.photos/seed/restaurant1/400/300',
      address: '123 MG Road',
      deliveryTimeMins: 30,
    },
    menu: [
      { id: 'item-1', name: 'Butter Chicken', price: 320, description: 'Creamy tomato-based curry with tender chicken', imageUrl: 'https://picsum.photos/seed/food1/300/300', isVeg: false, category: 'Main Course' },
      { id: 'item-2', name: 'Paneer Tikka', price: 260, description: 'Grilled cottage cheese marinated in spices', imageUrl: 'https://picsum.photos/seed/food2/300/300', isVeg: true, category: 'Starters' },
      { id: 'item-3', name: 'Garlic Naan', price: 60, description: 'Soft flatbread with garlic and butter', imageUrl: 'https://picsum.photos/seed/food3/300/300', isVeg: true, category: 'Breads' },
    ],
  },
  {
    id: 'sushi-zen',
    data: {
      name: 'Sushi Zen',
      cuisine: 'Japanese',
      rating: 4.6,
      imageUrl: 'https://picsum.photos/seed/restaurant2/400/300',
      address: '45 Park Street',
      deliveryTimeMins: 40,
    },
    menu: [
      { id: 'item-1', name: 'California Roll', price: 350, description: 'Crab, avocado, and cucumber roll', imageUrl: 'https://picsum.photos/seed/food4/300/300', isVeg: false, category: 'Sushi' },
      { id: 'item-2', name: 'Vegetable Tempura', price: 280, description: 'Crispy battered mixed vegetables', imageUrl: 'https://picsum.photos/seed/food5/300/300', isVeg: true, category: 'Starters' },
    ],
  },
];

async function seed() {
  for (const restaurant of restaurants) {
    const restaurantRef = db.collection('restaurants').doc(restaurant.id);
    await restaurantRef.set(restaurant.data);
    console.log(`✓ Created restaurant: ${restaurant.data.name}`);
    for (const item of restaurant.menu) {
      const { id, ...itemData } = item;
      await restaurantRef.collection('menu').doc(id).set(itemData);
      console.log(`  ✓ Added menu item: ${item.name}`);
    }
  }
  console.log('\n✅ Seeding complete! Check Firestore console to verify.');
  process.exit(0);
}

seed().catch((error) => {
  console.error('❌ Seeding failed:', error);
  process.exit(1);
});