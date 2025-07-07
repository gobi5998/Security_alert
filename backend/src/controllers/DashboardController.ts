import { Request, Response } from 'express';
import { DashboardStatsService } from '../models/DashboardStats';
import { AuthRequest } from '../middleware/auth';

export class DashboardController {
  private static statsService = new DashboardStatsService();

  static async getDashboardStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const stats = await DashboardController.statsService.getStats(userId);

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Get dashboard stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getThreatHistory(req: Request, res: Response): Promise<void> {
    try {
      const { period = '7D' } = req.query;
      const userId = (req as AuthRequest).user?.id;
      
      const history = await DashboardController.statsService.getThreatHistory(
        period as string,
        userId
      );

      res.status(200).json({
        success: true,
        data: history
      });
    } catch (error) {
      console.error('Get threat history error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getRiskScore(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const riskScore = await DashboardController.statsService.calculateRiskScore(userId);
      const riskLevel = await DashboardController.statsService.getRiskLevel(riskScore);
      const riskColor = await DashboardController.statsService.getRiskColor(riskScore);

      res.status(200).json({
        success: true,
        data: {
          riskScore,
          riskLevel,
          riskColor
        }
      });
    } catch (error) {
      console.error('Get risk score error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getResolutionRate(req: AuthRequest, res: Response): Promise<void> {
    try {
      const resolutionRate = await DashboardController.statsService.getResolutionRate();

      res.status(200).json({
        success: true,
        data: {
          resolutionRate
        }
      });
    } catch (error) {
      console.error('Get resolution rate error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
} 