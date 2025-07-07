import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';
import { AuthMiddleware } from '../middleware/auth';
import { ValidationMiddleware, AuthSchemas } from '../middleware/validation';

const router = Router();

// Public routes
router.post('/login', 
  ValidationMiddleware.validate(AuthSchemas.login),
  AuthController.login
);

router.post('/register', 
  ValidationMiddleware.validate(AuthSchemas.register),
  AuthController.register
);

// Protected routes
router.post('/logout', 
  AuthMiddleware.authenticate,
  AuthController.logout
);

router.get('/profile', 
  AuthMiddleware.authenticate,
  AuthController.getProfile
);

router.put('/profile', 
  AuthMiddleware.authenticate,
  ValidationMiddleware.validate(AuthSchemas.register), // Changed from update to register since update doesn't exist
  AuthController.updateProfile
);

// Add /forgot-password, /google, /facebook as needed

export default router; 