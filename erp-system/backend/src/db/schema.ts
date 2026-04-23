import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';

// ร้านอาหาร
export const restaurants = sqliteTable('restaurants', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  address: text('address'),
  phone: text('phone'),
});

// รายการอาหาร
export const menuItems = sqliteTable('menu_items', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  description: text('description'),
  price: real('price').notNull(),
  category: text('category').notNull(), // เช่น 'Main', 'Drink', 'Dessert'
  isAvailable: integer('is_available', { mode: 'boolean' }).default(true),
});

// คำสั่งซื้อ
export const orders = sqliteTable('orders', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  tableNumber: text('table_number').notNull(),
  status: text('status').notNull().default('pending'), // 'pending', 'cooking', 'served', 'paid', 'cancelled'
  totalAmount: real('total_amount').default(0),
  createdAt: integer('created_at', { mode: 'timestamp' }).$defaultFn(() => new Date()),
});

// รายการในคำสั่งซื้อ (Line Items)
export const orderItems = sqliteTable('order_items', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  orderId: integer('order_id').references(() => orders.id),
  menuItemId: integer('menu_item_id').references(() => menuItems.id),
  quantity: integer('quantity').notNull(),
  priceAtTime: real('price_at_time').notNull(), // เก็บราคา ณ ตอนสั่งเผื่อราคาเมนูเปลี่ยน
});

// คลังวัตถุดิบ
export const inventory = sqliteTable('inventory', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  itemName: text('item_name').notNull(),
  quantity: real('quantity').notNull(),
  unit: text('unit').notNull(), // เช่น 'kg', 'liter', 'piece'
  minThreshold: real('min_threshold').default(10), // จุดสั่งซื้อซ้ำ
});
