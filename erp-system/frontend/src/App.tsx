import React from 'react'

function App() {
  const [orders, setOrders] = React.useState([
    { id: 101, table: 'T1', status: 'Cooking', total: 125 },
    { id: 102, table: 'T5', status: 'Pending', total: 450 },
  ])

  return (
    <div className="min-h-screen font-sans">
      {/* Navigation */}
      <nav className="bg-brand-dark text-white p-4 shadow-lg flex justify-between items-center">
        <h1 className="text-2xl font-bold text-brand-primary">Oracle ERP: Restaurant</h1>
        <div className="space-x-4 text-sm font-medium">
          <a href="#" className="hover:text-brand-primary">Orders</a>
          <a href="#" className="hover:text-brand-primary">Menu</a>
          <a href="#" className="hover:text-brand-primary">Inventory</a>
          <button className="bg-brand-primary px-3 py-1 rounded text-brand-dark font-bold hover:bg-orange-400 transition">
            New Order
          </button>
        </div>
      </nav>

      {/* Main Content */}
      <main className="p-8 max-w-6xl mx-auto">
        <header className="mb-8">
          <h2 className="text-3xl font-bold mb-2">Order Dashboard</h2>
          <p className="text-slate-500">Live monitoring of active table orders.</p>
        </header>

        {/* Dashboard Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {orders.map((order) => (
            <div key={order.id} className="bg-white border-2 border-slate-200 rounded-xl p-5 shadow-sm hover:border-brand-primary transition">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">Table</span>
                  <p className="text-xl font-black">{order.table}</p>
                </div>
                <span className={`px-2 py-1 rounded text-xs font-bold ${
                  order.status === 'Cooking' ? 'bg-orange-100 text-orange-600' : 'bg-slate-100 text-slate-600'
                }`}>
                  {order.status}
                </span>
              </div>
              
              <div className="border-t border-slate-100 pt-4 flex justify-between items-center">
                <p className="text-lg font-bold">฿{order.total}</p>
                <button className="text-brand-primary text-sm font-bold hover:underline">
                  View Details →
                </button>
              </div>
            </div>
          ))}

          {/* New Order Empty State / Prompt */}
          <div className="border-2 border-dashed border-slate-300 rounded-xl p-5 flex flex-col items-center justify-center opacity-60 hover:opacity-100 transition cursor-pointer">
             <span className="text-4xl mb-2">➕</span>
             <p className="font-bold">Add New Table</p>
          </div>
        </div>
      </main>
    </div>
  )
}

export default App
