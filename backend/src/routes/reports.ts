import { Router } from 'express';
import { MalwareReportController } from '../controllers/MalwareReportController';
import { AuthMiddleware } from '../middleware/auth';
import { ValidationMiddleware, MalwareReportSchemas } from '../middleware/validation';

const router = Router();

// All routes require authentication
router.use(AuthMiddleware.authenticate);

// Get all reports for the authenticated user
router.get('/', MalwareReportController.getAllReports);

// Get reports by status
router.get('/status/:status', MalwareReportController.getReportsByStatus);

// Get report statistics
router.get('/stats', MalwareReportController.getReportStats);

// Get specific report by ID
router.get('/:id', MalwareReportController.getReportById);

// Create new report
router.post('/', 
  ValidationMiddleware.validate(MalwareReportSchemas.create),
  MalwareReportController.createReport
);

// Update report
router.put('/:id', 
  ValidationMiddleware.validate(MalwareReportSchemas.update),
  MalwareReportController.updateReport
);

// Delete report
router.delete('/:id', MalwareReportController.deleteReport);

// Submit report
router.patch('/:id/submit', MalwareReportController.submitReport);

// Process report
router.patch('/:id/process', MalwareReportController.processReport);

// Resolve report
router.patch('/:id/resolve', MalwareReportController.resolveReport);

export default router; 