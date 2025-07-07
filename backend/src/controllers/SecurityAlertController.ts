import { Request, Response } from 'express';
import { SecurityAlertService, ICreateSecurityAlert, IUpdateSecurityAlert } from '../models/SecurityAlert';
import { AuthRequest } from '../middleware/auth';

export class SecurityAlertController {
  private static alertService = new SecurityAlertService();

  static async getAllAlerts(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const alerts = await SecurityAlertController.alertService.findAll(userId);

      res.status(200).json({
        success: true,
        data: alerts,
        count: alerts.length
      });
    } catch (error) {
      console.error('Get all alerts error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getAlertById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const alert = await SecurityAlertController.alertService.findById(id);

      if (!alert) {
        res.status(404).json({
          success: false,
          message: 'Alert not found'
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: alert
      });
    } catch (error) {
      console.error('Get alert by ID error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async createAlert(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const alertData: ICreateSecurityAlert = {
        ...req.body,
        userId
      };

      const newAlert = await SecurityAlertController.alertService.create(alertData);

      res.status(201).json({
        success: true,
        message: 'Alert created successfully',
        data: newAlert
      });
    } catch (error) {
      console.error('Create alert error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async updateAlert(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const updateData: IUpdateSecurityAlert = req.body;

      const updatedAlert = await SecurityAlertController.alertService.update(id, updateData);

      if (!updatedAlert) {
        res.status(404).json({
          success: false,
          message: 'Alert not found'
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: 'Alert updated successfully',
        data: updatedAlert
      });
    } catch (error) {
      console.error('Update alert error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async deleteAlert(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const deleted = await SecurityAlertController.alertService.delete(id);

      if (!deleted) {
        res.status(404).json({
          success: false,
          message: 'Alert not found'
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: 'Alert deleted successfully'
      });
    } catch (error) {
      console.error('Delete alert error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async resolveAlert(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const resolvedAlert = await SecurityAlertController.alertService.resolve(id);

      if (!resolvedAlert) {
        res.status(404).json({
          success: false,
          message: 'Alert not found'
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: 'Alert resolved successfully',
        data: resolvedAlert
      });
    } catch (error) {
      console.error('Resolve alert error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getAlertStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const stats = await SecurityAlertController.alertService.getStats(userId);

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Get alert stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
} 