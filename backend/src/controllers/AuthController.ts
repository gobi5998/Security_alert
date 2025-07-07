import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User, { ILoginRequest } from '../models/User';

export class AuthController {

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { username, password }: ILoginRequest = req.body;

      // Find user by username
      const user = await User.findOne({ username });
      
      if (!user) {
        res.status(401).json({
          success: false,
          message: 'Invalid username or password'
        });
        return;
      }

      // Check password
      const isPasswordValid = await bcrypt.compare(password, user.password || '');
      
      if (!isPasswordValid) {
        res.status(401).json({
          success: false,
          message: 'Invalid username or password'
        });
        return;
      }

      // Generate JWT token
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        console.error('JWT_SECRET is not configured in environment variables');
        res.status(500).json({
          success: false,
          message: 'Server configuration error: JWT secret not configured. Please check your .env file.'
        });
        return;
      }

      const token = jwt.sign(
        { userId: user._id },
        jwtSecret as any,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as any
      );

      // Return user data without password
      const userResponse = {
        id: user._id,
        username: user.username,
        email: user.email,
        createdAt: user.createdAt,
      };

      res.status(200).json({
        success: true,
        message: 'Login successful',
        user: userResponse,
        token
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async register(req: Request, res: Response): Promise<void> {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      res.status(400).json({ message: 'All fields are required.' });
      return;
    }
    const existing = await User.findOne({ $or: [{ username }, { email }] });
    if (existing) {
      res.status(409).json({ message: 'Username or email already exists.' });
      return;
    }

    const hash = await bcrypt.hash(password, 12);
    const user = new User({ username, email, password: hash });
    await user.save();
    res.status(201).json({ message: 'User registered successfully.' });
  }

  static async logout(req: Request, res: Response): Promise<void> {
    try {
      // In a real application, you might want to blacklist the token
      // For now, we'll just return a success response
      res.status(200).json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      console.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      // The user should be available from auth middleware
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
        return;
      }

      const user = await User.findById(userId);
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      // Return user data without password
      const userResponse = {
        id: user._id,
        username: user.username,
        email: user.email,
        createdAt: user.createdAt,
      };

      res.status(200).json({
        success: true,
        user: userResponse
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
        return;
      }

      const { username, email } = req.body;

      // Check if username is being changed and if it already exists
      if (username) {
        const existingUser = await User.findOne({ username });
        if (existingUser && existingUser.id !== userId) {
          res.status(409).json({
            success: false,
            message: 'Username already exists'
          });
          return;
        }
      }

      // Check if email is being changed and if it already exists
      if (email) {
        const existingEmail = await User.findOne({ email });
        if (existingEmail && existingEmail.id !== userId) {
          res.status(409).json({
            success: false,
            message: 'Email already exists'
          });
          return;
        }
      }

      const update: any = {};
      if (username) update.username = username;
      if (email) update.email = email;
      const updatedUser = await User.findByIdAndUpdate(userId, update, { new: true });

      if (!updatedUser) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      // Return user data without password
      const userResponse = {
        id: updatedUser._id,
        username: updatedUser.username,
        email: updatedUser.email,
        createdAt: updatedUser.createdAt,
      };

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        user: userResponse
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Add Google/Facebook login, forgot password, etc. as needed
}

function isStrongPassword(password: string): boolean {
  return (
    password.length >= 8 &&
    /[A-Z]/.test(password) &&
    /[a-z]/.test(password) &&
    /[0-9]/.test(password) &&
    /[^A-Za-z0-9]/.test(password)
  );
} 