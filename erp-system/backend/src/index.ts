import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

const app = new Hono()

// --- Validation Schemas ---
const orderSchema = z.object({
  tableNumber: z.string().min(1),
  items: z.array(z.object({
    menuItemId: z.number(),
    quantity: z.number().min(1),
  }))
})

// --- API Routes ---

// 1. ดึงรายการอาหารทั้งหมด
app.get('/menu', (c) => {
  // TODO: Fetch from Drizzle DB
  return c.json({
    status: 'success',
    data: [
      { id: 1, name: 'Pad Thai', price: 80, category: 'Main' },
      { id: 2, name: 'Thai Tea', price: 45, category: 'Drink' }
    ]
  })
})

// 2. สร้างคำสั่งซื้อใหม่
app.post('/orders', zValidator('json', orderSchema), (c) => {
  const data = c.req.valid('json')
  // TODO: Insert into Drizzle DB
  console.log('Received Order:', data)
  return c.json({
    status: 'success',
    message: 'Order created',
    orderId: Math.floor(Math.random() * 1000)
  }, 201)
})

// 3. ตรวจสอบสถานะคลัง (Health Check)
app.get('/inventory/status', (c) => {
  return c.json({
    status: 'healthy',
    message: 'Inventory items within threshold'
  })
})

export default app
export type AppType = typeof app // สำหรับ Hono RPC (Type-Safe Frontend)
