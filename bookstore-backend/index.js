const express = require('express');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const cors = require('cors');

const app = express();
const port = 3000;

// PostgreSQL config
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'bd1',
  password: '123',
  port: 5432,
});

// Middlewares
app.use(cors());
app.use(bodyParser.json());

// User Register
app.post('/api/register', async (req, res) => {
  const { name, email, password } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);
  try {
    await pool.query(
      'INSERT INTO users (name, email, password) VALUES ($1, $2, $3)',
      [name, email, hashedPassword]
    );
    res.status(201).send({ message: 'User registered' });
  } catch (err) {
    res.status(500).send({ error: 'Email already in use' });
  }
});

// User Login
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = result.rows[0];
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).send({ error: 'Invalid credentials' });
  }
  res.send({ message: 'Login successful', user: { id: user.id, name: user.name } });
});

// Add Book (with base64 image)
app.post('/api/books', async (req, res) => {
  const { title, author, description, price, stock, photo_base64 } = req.body;
  try {
    await pool.query(
      `INSERT INTO books (title, author, description, price, stock, photo_base64)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [title, author, description, price, stock, photo_base64]
    );
    res.status(201).send({ message: 'Book added' });
  } catch (err) {
    res.status(500).send({ error: 'Error adding book' });
  }
});

// Get All Books
app.get('/api/books', async (req, res) => {
  const result = await pool.query('SELECT * FROM books');
  res.send(result.rows);
});

// Get Single Book
app.get('/api/books/:id', async (req, res) => {
  const result = await pool.query('SELECT * FROM books WHERE id = $1', [req.params.id]);
  const book = result.rows[0];
  if (!book) return res.status(404).send({ error: 'Book not found' });
  res.send(book);
});

// Update Book
app.put('/api/books/:id', async (req, res) => {
  const { title, author, description, price, stock, photo_base64 } = req.body;
  try {
    await pool.query(
      `UPDATE books SET title = $1, author = $2, description = $3,
       price = $4, stock = $5, photo_base64 = $6 WHERE id = $7`,
      [title, author, description, price, stock, photo_base64, req.params.id]
    );
    res.send({ message: 'Book updated' });
  } catch (err) {
    res.status(500).send({ error: 'Error updating book' });
  }
});

// Delete Book
app.delete('/api/books/:id', async (req, res) => {
  await pool.query('DELETE FROM books WHERE id = $1', [req.params.id]);
  res.send({ message: 'Book deleted' });
});
app.post('/api/cart/add', async (req, res) => {
    const { userId, bookId, quantity } = req.body;
    if (!userId || !bookId) {
      return res.status(400).send({ error: 'Missing userId or bookId' });
    }
  
    try {
      // Check if the book is already in the cart
      const existing = await pool.query(
        'SELECT * FROM cart_items WHERE user_id = $1 AND book_id = $2',
        [userId, bookId]
      );
  
      if (existing.rows.length > 0) {
        // Update quantity
        const newQuantity = existing.rows[0].quantity + (quantity || 1);
        await pool.query(
          'UPDATE cart_items SET quantity = $1 WHERE user_id = $2 AND book_id = $3',
          [newQuantity, userId, bookId]
        );
      } else {
        // Insert new cart item
        await pool.query(
          'INSERT INTO cart_items (user_id, book_id, quantity) VALUES ($1, $2, $3)',
          [userId, bookId, quantity || 1]
        );
      }
      res.send({ message: 'Book added to cart' });
    } catch (err) {
      console.error(err);
      res.status(500).send({ error: 'Error adding book to cart' });
    }
  });
  
  // Get User Cart Items
  app.get('/api/cart/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
      const result = await pool.query(
        `SELECT ci.quantity, b.* FROM cart_items ci
         JOIN books b ON ci.book_id = b.id
         WHERE ci.user_id = $1`,
        [userId]
      );
      res.send(result.rows);
    } catch (err) {
      console.error(err);
      res.status(500).send({ error: 'Error fetching cart' });
    }
  });
  
  // Optional: Remove Book from Cart
  app.delete('/api/cart/remove', async (req, res) => {
    const { userId, bookId } = req.body;
    if (!userId || !bookId) {
      return res.status(400).send({ error: 'Missing userId or bookId' });
    }
  
    try {
      await pool.query(
        'DELETE FROM cart_items WHERE user_id = $1 AND book_id = $2',
        [userId, bookId]
      );
      res.send({ message: 'Book removed from cart' });
    } catch (err) {
      console.error(err);
      res.status(500).send({ error: 'Error removing book from cart' });
    }
  });
// Place Order (from cart)
app.post('/api/orders/place', async (req, res) => {
    const { userId } = req.body;
    if (!userId) return res.status(400).send({ error: 'Missing userId' });
  
    try {
      // Get cart items for the user
      const cartResult = await pool.query(
        `SELECT ci.quantity, b.id, b.price FROM cart_items ci
         JOIN books b ON ci.book_id = b.id
         WHERE ci.user_id = $1`,
        [userId]
      );
      const cartItems = cartResult.rows;
      if (cartItems.length === 0) {
        return res.status(400).send({ error: 'Cart is empty' });
      }
  
      // Calculate total price
      const total = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  
      // Start transaction
      await pool.query('BEGIN');
  
      // Insert new order
      const orderResult = await pool.query(
        `INSERT INTO orders (user_id, total) VALUES ($1, $2) RETURNING id`,
        [userId, total]
      );
      const orderId = orderResult.rows[0].id;
  
      // Insert order items
      for (const item of cartItems) {
        await pool.query(
          `INSERT INTO order_items (order_id, book_id, quantity, price)
           VALUES ($1, $2, $3, $4)`,
          [orderId, item.id, item.quantity, item.price]
        );
      }
  
      // Clear user's cart
      await pool.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);
  
      // Commit transaction
      await pool.query('COMMIT');
  
      res.status(201).send({ message: 'Order placed', orderId });
    } catch (err) {
      await pool.query('ROLLBACK');
      console.error(err);
      res.status(500).send({ error: 'Error placing order' });
    }
  });
  
  // Get User Orders with Items
  app.get('/api/orders/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
      // Get all orders for user
      const ordersResult = await pool.query(
        'SELECT id, created_at FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
        [userId]
      );
      const orders = ordersResult.rows;
  
      // For each order, get its items
      for (const order of orders) {
        const itemsResult = await pool.query(
          `SELECT oi.quantity, b.title, b.author, b.price, b.photo_base64
           FROM order_items oi
           JOIN books b ON oi.book_id = b.id
           WHERE oi.order_id = $1`,
          [order.id]
        );
        order.items = itemsResult.rows;
      }
  
      res.send(orders);
    } catch (err) {
      console.error(err);
      res.status(500).send({ error: 'Error fetching orders' });
    }
  });
  
// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
