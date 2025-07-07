import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    username: string;
    email: string;
  };
}

export class AuthMiddleware {
  static async authenticate(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ 
          success: false, 
          message: 'Access token required' 
        });
        return;
      }

      const token = authHeader.substring(7); // Remove 'Bearer ' prefix
      
      if (!process.env.JWT_SECRET) {
        res.status(500).json({ 
          success: false, 
          message: 'JWT secret not configured' 
        });
        return;
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET) as any;
      
      if (!decoded.userId) {
        res.status(401).json({ 
          success: false, 
          message: 'Invalid token format' 
        });
        return;
      }

      const user = await User.findById(decoded.userId);
      
      if (!user) {
        res.status(401).json({ 
          success: false, 
          message: 'User not found' 
        });
        return;
      }
      const u = user as { _id: any; username: string; email: string };
      req.user = {
        id: u._id.toString(),
        username: u.username,
        email: u.email,
      };

      next();
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        res.status(401).json({ 
          success: false, 
          message: 'Invalid token' 
        });
      } else if (error instanceof jwt.TokenExpiredError) {
        res.status(401).json({ 
          success: false, 
          message: 'Token expired' 
        });
      } else {
        console.error('Auth middleware error:', error);
        res.status(500).json({ 
          success: false, 
          message: 'Authentication error' 
        });
      }
    }
  }

  static async optionalAuth(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        next();
        return;
      }

      const token = authHeader.substring(7);
      
      if (!process.env.JWT_SECRET) {
        next();
        return;
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET) as any;
      
      if (decoded.userId) {
        const user = await User.findById(decoded.userId);
        
        if (user) {
          const u = user as { _id: any; username: string; email: string };
          req.user = {
            id: u._id.toString(),
            username: u.username,
            email: u.email,
          };
        }
      }

      next();
    } catch (error) {
      // For optional auth, we just continue without setting user
      next();
    }
  }
} 