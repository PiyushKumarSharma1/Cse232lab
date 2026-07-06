import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { query } from '../db';
import { CreateUser, User } from '../types';

export class AuthService {
  async register(userData: CreateUser) {
    const { email, password, role, firstName, lastName, phone } = userData;

    // Check if user already exists
    const existingUsers = await query<User[]>(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (existingUsers && existingUsers.length > 0) {
      throw new Error('Email already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user
    const users = await query<User[]>(
      `INSERT INTO users (email, password_hash, role, first_name, last_name, phone)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [email, passwordHash, role, firstName, lastName, phone || null]
    );

    const user = users[0];

    // Generate tokens
    const token = this.generateToken(user.id);
    const refreshToken = this.generateRefreshToken(user.id);

    return {
      user: this.sanitizeUser(user),
      token,
      refreshToken,
    };
  }

  async login(email: string, password: string) {
    const users = await query<User[]>(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (!users || users.length === 0) {
      throw new Error('Invalid credentials');
    }

    const user = users[0];
    const isValid = await bcrypt.compare(password, user.passwordHash);

    if (!isValid) {
      throw new Error('Invalid credentials');
    }

    // Generate tokens
    const token = this.generateToken(user.id);
    const refreshToken = this.generateRefreshToken(user.id);

    return {
      user: this.sanitizeUser(user),
      token,
      refreshToken,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET!) as { userId: string };
      
      const users = await query<User[]>(
        'SELECT * FROM users WHERE id = $1',
        [decoded.userId]
      );

      if (!users || users.length === 0) {
        throw new Error('User not found');
      }

      const user = users[0];
      const newToken = this.generateToken(user.id);
      const newRefreshToken = this.generateRefreshToken(user.id);

      return {
        user: this.sanitizeUser(user),
        token: newToken,
        refreshToken: newRefreshToken,
      };
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  private generateToken(userId: string): string {
    return jwt.sign(
      { userId },
      process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
  }

  private generateRefreshToken(userId: string): string {
    return jwt.sign(
      { userId },
      process.env.JWT_SECRET!,
      { expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '30d' }
    );
  }

  private sanitizeUser(user: User) {
    const { passwordHash, ...sanitized } = user;
    return sanitized;
  }
}
