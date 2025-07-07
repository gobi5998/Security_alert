import { Router } from 'express';
import { DashboardController } from '../controllers/DashboardController';
import { AuthMiddleware } from '../middleware/auth';
import { ValidationMiddleware, QuerySchemas } from '../middleware/validation';

const router = Router();

// All routes require authentication
router.use(AuthMiddleware.authenticate);

// Get dashboard statistics
router.get('/stats', DashboardController.getDashboardStats);

// Get threat history
router.get('/threats', 
  ValidationMiddleware.validateQuery(QuerySchemas.period),
  DashboardController.getThreatHistory
);

// Get risk score
router.get('/risk-score', DashboardController.getRiskScore);

// Get resolution rate
router.get('/resolution-rate', DashboardController.getResolutionRate);

export default router; 