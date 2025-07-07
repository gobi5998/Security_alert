export interface IDashboardStats {
  totalAlerts: number;
  resolvedAlerts: number;
  pendingAlerts: number;
  alertsByType: Record<string, number>;
  alertsBySeverity: Record<string, number>;
  threatTrendData: number[];
  threatBarData: number[];
  riskScore: number;
}

export interface IThreatHistory {
  date: string;
  count: number;
}

// Mock data for development
export const mockDashboardStats: IDashboardStats = {
  totalAlerts: 50,
  resolvedAlerts: 35,
  pendingAlerts: 15,
  alertsByType: {
    spam: 20,
    malware: 15,
    fraud: 10,
    phishing: 3,
    other: 2,
  },
  alertsBySeverity: {
    low: 25,
    medium: 15,
    high: 8,
    critical: 2,
  },
  threatTrendData: [30, 35, 40, 50, 45, 38, 42],
  threatBarData: [10, 20, 15, 30, 25, 20, 10],
  riskScore: 75.0,
};

export const mockThreatHistory: IThreatHistory[] = [
  { date: '2024-01-01', count: 10 },
  { date: '2024-01-02', count: 15 },
  { date: '2024-01-03', count: 8 },
  { date: '2024-01-04', count: 20 },
  { date: '2024-01-05', count: 12 },
  { date: '2024-01-06', count: 18 },
  { date: '2024-01-07', count: 14 },
];

export class DashboardStatsService {
  private stats: IDashboardStats = { ...mockDashboardStats };
  private threatHistory: IThreatHistory[] = [...mockThreatHistory];

  async getStats(userId?: string): Promise<IDashboardStats> {
    // In a real application, you would calculate these stats from the database
    // For now, we'll return mock data
    return this.stats;
  }

  async getThreatHistory(period: string = '7D', userId?: string): Promise<IThreatHistory[]> {
    // In a real application, you would filter by period and user
    // For now, we'll return mock data
    return this.threatHistory;
  }

  async updateStats(newStats: Partial<IDashboardStats>): Promise<IDashboardStats> {
    this.stats = { ...this.stats, ...newStats };
    return this.stats;
  }

  async calculateRiskScore(userId?: string): Promise<number> {
    // In a real application, you would calculate risk score based on:
    // - Number of unresolved alerts
    // - Severity of recent threats
    // - User behavior patterns
    // - Historical data
    
    const baseScore = 50;
    const unresolvedAlerts = this.stats.pendingAlerts;
    const criticalAlerts = this.stats.alertsBySeverity.critical || 0;
    const highAlerts = this.stats.alertsBySeverity.high || 0;
    
    let riskScore = baseScore;
    riskScore += unresolvedAlerts * 2;
    riskScore += criticalAlerts * 10;
    riskScore += highAlerts * 5;
    
    // Cap at 100
    return Math.min(riskScore, 100);
  }

  async getRiskLevel(riskScore: number): Promise<string> {
    if (riskScore < 30) return 'Low';
    if (riskScore < 60) return 'Medium';
    if (riskScore < 80) return 'High';
    return 'Critical';
  }

  async getRiskColor(riskScore: number): Promise<string> {
    if (riskScore < 30) return '#4CAF50';
    if (riskScore < 60) return '#FF9800';
    if (riskScore < 80) return '#F44336';
    return '#9C27B0';
  }

  async getResolutionRate(): Promise<number> {
    if (this.stats.totalAlerts === 0) return 0.0;
    return (this.stats.resolvedAlerts / this.stats.totalAlerts) * 100;
  }
} 