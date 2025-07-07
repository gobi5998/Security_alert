export enum AlertSeverity {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical'
}

export enum AlertType {
  SPAM = 'spam',
  MALWARE = 'malware',
  FRAUD = 'fraud',
  PHISHING = 'phishing',
  OTHER = 'other'
}

export interface ISecurityAlert {
  id: string;
  title: string;
  description: string;
  severity: AlertSeverity;
  type: AlertType;
  timestamp: Date;
  isResolved: boolean;
  location?: string;
  malwareType?: string;
  infectedDeviceType?: string;
  operatingSystem?: string;
  detectionMethod?: string;
  fileName?: string;
  name?: string;
  systemAffected?: string;
  metadata?: Record<string, any>;
  userId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ICreateSecurityAlert {
  title: string;
  description: string;
  severity: AlertSeverity;
  type: AlertType;
  location?: string;
  malwareType?: string;
  infectedDeviceType?: string;
  operatingSystem?: string;
  detectionMethod?: string;
  fileName?: string;
  name?: string;
  systemAffected?: string;
  metadata?: Record<string, any>;
  userId?: string;
}

export interface IUpdateSecurityAlert {
  title?: string;
  description?: string;
  severity?: AlertSeverity;
  type?: AlertType;
  isResolved?: boolean;
  location?: string;
  malwareType?: string;
  infectedDeviceType?: string;
  operatingSystem?: string;
  detectionMethod?: string;
  fileName?: string;
  name?: string;
  systemAffected?: string;
  metadata?: Record<string, any>;
}

// Mock data for development
export const mockSecurityAlerts: ISecurityAlert[] = [
  {
    id: '1',
    title: 'Suspicious Email Detected',
    description: 'A phishing email was detected in your inbox',
    severity: AlertSeverity.HIGH,
    type: AlertType.PHISHING,
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
    isResolved: false,
    location: 'Email Inbox',
    userId: '1',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
  },
  {
    id: '2',
    title: 'Malware Alert',
    description: 'Potential malware detected in downloaded file',
    severity: AlertSeverity.CRITICAL,
    type: AlertType.MALWARE,
    timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
    isResolved: true,
    location: 'Downloads folder',
    malwareType: 'Trojan',
    infectedDeviceType: 'Desktop',
    operatingSystem: 'Windows 10',
    detectionMethod: 'Antivirus scan',
    fileName: 'suspicious_file.exe',
    userId: '1',
    createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
  },
  {
    id: '3',
    title: 'Suspicious Website',
    description: 'Attempted access to known phishing website',
    severity: AlertSeverity.MEDIUM,
    type: AlertType.PHISHING,
    timestamp: new Date(Date.now() - 30 * 60 * 1000), // 30 minutes ago
    isResolved: false,
    location: 'Browser',
    userId: '1',
    createdAt: new Date(Date.now() - 30 * 60 * 1000),
    updatedAt: new Date(Date.now() - 30 * 60 * 1000),
  },
];

export class SecurityAlertService {
  private alerts: ISecurityAlert[] = [...mockSecurityAlerts];

  async findAll(userId?: string): Promise<ISecurityAlert[]> {
    if (userId) {
      return this.alerts.filter(alert => alert.userId === userId);
    }
    return this.alerts;
  }

  async findById(id: string): Promise<ISecurityAlert | null> {
    return this.alerts.find(alert => alert.id === id) || null;
  }

  async create(alertData: ICreateSecurityAlert): Promise<ISecurityAlert> {
    const newAlert: ISecurityAlert = {
      ...alertData,
      id: this.generateId(),
      timestamp: new Date(),
      isResolved: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    this.alerts.push(newAlert);
    return newAlert;
  }

  async update(id: string, updateData: IUpdateSecurityAlert): Promise<ISecurityAlert | null> {
    const alertIndex = this.alerts.findIndex(alert => alert.id === id);
    if (alertIndex === -1) return null;

    this.alerts[alertIndex] = {
      ...this.alerts[alertIndex],
      ...updateData,
      updatedAt: new Date(),
    };

    return this.alerts[alertIndex];
  }

  async delete(id: string): Promise<boolean> {
    const alertIndex = this.alerts.findIndex(alert => alert.id === id);
    if (alertIndex === -1) return false;

    this.alerts.splice(alertIndex, 1);
    return true;
  }

  async resolve(id: string): Promise<ISecurityAlert | null> {
    return this.update(id, { isResolved: true });
  }

  async getStats(userId?: string): Promise<{
    total: number;
    resolved: number;
    pending: number;
    byType: Record<AlertType, number>;
    bySeverity: Record<AlertSeverity, number>;
  }> {
    const userAlerts = userId 
      ? this.alerts.filter(alert => alert.userId === userId)
      : this.alerts;

    const total = userAlerts.length;
    const resolved = userAlerts.filter(alert => alert.isResolved).length;
    const pending = total - resolved;

    const byType = Object.values(AlertType).reduce((acc, type) => {
      acc[type] = userAlerts.filter(alert => alert.type === type).length;
      return acc;
    }, {} as Record<AlertType, number>);

    const bySeverity = Object.values(AlertSeverity).reduce((acc, severity) => {
      acc[severity] = userAlerts.filter(alert => alert.severity === severity).length;
      return acc;
    }, {} as Record<AlertSeverity, number>);

    return { total, resolved, pending, byType, bySeverity };
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 9);
  }
} 