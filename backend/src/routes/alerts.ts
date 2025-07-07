import { Router } from 'express';
import { SecurityAlertController } from '../controllers/SecurityAlertController';
import { AuthMiddleware } from '../middleware/auth';
import { ValidationMiddleware, SecurityAlertSchemas } from '../middleware/validation';

const router = Router();

// All routes require authentication
router.use(AuthMiddleware.authenticate);

// Get all alerts for the authenticated user
router.get('/', SecurityAlertController.getAllAlerts);

// Get alert statistics
router.get('/stats', SecurityAlertController.getAlertStats);

// Get specific alert by ID
router.get('/:id', SecurityAlertController.getAlertById);

// Create new alert
router.post('/', 
  ValidationMiddleware.validate(SecurityAlertSchemas.create),
  SecurityAlertController.createAlert
);

// Update alert
router.put('/:id', 
  ValidationMiddleware.validate(SecurityAlertSchemas.update),
  SecurityAlertController.updateAlert
);

// Delete alert
router.delete('/:id', SecurityAlertController.deleteAlert);

// Resolve alert
router.patch('/:id/resolve', SecurityAlertController.resolveAlert);

export default router; 