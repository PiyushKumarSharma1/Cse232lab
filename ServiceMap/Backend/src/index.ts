import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { Server } from 'socket.io';
import http from 'http';

// Import routes
import authRoutes from './routes/auth.routes';

dotenv.config();

const app = express();
const server = http.createServer(app);

// Socket.IO for real-time features
const io = new Server(server, {
  cors: {
    origin: process.env.CUSTOMER_APP_URL || '*',
    methods: ['GET', 'POST'],
  },
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Join booking room for real-time updates
  socket.on('join-booking', (bookingId: string) => {
    socket.join(`booking:${bookingId}`);
    console.log(`Client ${socket.id} joined booking room: ${bookingId}`);
  });

  // Provider location updates
  socket.on('provider-location', (data: { bookingId: string; latitude: number; longitude: number }) => {
    socket.to(`booking:${data.bookingId}`).emit('location-update', {
      providerId: socket.id,
      latitude: data.latitude,
      longitude: data.longitude,
      timestamp: new Date().toISOString(),
    });
  });

  // Booking status updates
  socket.on('booking-status-update', (data: { bookingId: string; status: string }) => {
    io.to(`booking:${data.bookingId}`).emit('status-update', {
      bookingId: data.bookingId,
      status: data.status,
      timestamp: new Date().toISOString(),
    });
  });

  // Message events
  socket.on('send-message', (data: { receiverId: string; content: string; bookingId?: string }) => {
    // In production, save to database and emit to receiver
    socket.emit('message-sent', {
      id: `msg_${Date.now()}`,
      ...data,
      createdAt: new Date().toISOString(),
    });
  });

  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🚀 ServiceMap API server running on port ${PORT}`);
  console.log(`📡 WebSocket server ready`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
});

export { app, io };
