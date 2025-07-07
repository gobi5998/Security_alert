import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';

export class ValidationMiddleware {
  static validate(schema: Joi.ObjectSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
      const { error } = schema.validate(req.body);
      
      if (error) {
        const errorMessage = error.details.map(detail => detail.message).join(', ');
        res.status(400).json({
          success: false,
          message: 'Validation error',
          errors: errorMessage
        });
        return;
      }
      
      next();
    };
  }

  static validateQuery(schema: Joi.ObjectSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
      const { error } = schema.validate(req.query);
      
      if (error) {
        const errorMessage = error.details.map(detail => detail.message).join(', ');
        res.status(400).json({
          success: false,
          message: 'Query validation error',
          errors: errorMessage
        });
        return;
      }
      
      next();
    };
  }

  static validateParams(schema: Joi.ObjectSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
      const { error } = schema.validate(req.params);
      
      if (error) {
        const errorMessage = error.details.map(detail => detail.message).join(', ');
        res.status(400).json({
          success: false,
          message: 'Parameter validation error',
          errors: errorMessage
        });
        return;
      }
      
      next();
    };
  }
}

// Validation schemas
export const AuthSchemas = {
  login: Joi.object({
    username: Joi.string().required().min(3).max(50),
    password: Joi.string().required().min(6).max(100),
  }),

  register: Joi.object({
    username: Joi.string().required().min(3).max(50),
    email: Joi.string().email().required(),
    password: Joi.string().required().min(6).max(100),
  }),
};

export const SecurityAlertSchemas = {
  create: Joi.object({
    title: Joi.string().required().min(1).max(200),
    description: Joi.string().required().min(1).max(1000),
    severity: Joi.string().valid('low', 'medium', 'high', 'critical').required(),
    type: Joi.string().valid('spam', 'malware', 'fraud', 'phishing', 'other').required(),
    location: Joi.string().optional().max(200),
    malwareType: Joi.string().optional().max(100),
    infectedDeviceType: Joi.string().optional().max(100),
    operatingSystem: Joi.string().optional().max(100),
    detectionMethod: Joi.string().optional().max(200),
    fileName: Joi.string().optional().max(200),
    name: Joi.string().optional().max(100),
    systemAffected: Joi.string().optional().max(200),
    metadata: Joi.object().optional(),
  }),

  update: Joi.object({
    title: Joi.string().optional().min(1).max(200),
    description: Joi.string().optional().min(1).max(1000),
    severity: Joi.string().valid('low', 'medium', 'high', 'critical').optional(),
    type: Joi.string().valid('spam', 'malware', 'fraud', 'phishing', 'other').optional(),
    isResolved: Joi.boolean().optional(),
    location: Joi.string().optional().max(200),
    malwareType: Joi.string().optional().max(100),
    infectedDeviceType: Joi.string().optional().max(100),
    operatingSystem: Joi.string().optional().max(100),
    detectionMethod: Joi.string().optional().max(200),
    fileName: Joi.string().optional().max(200),
    name: Joi.string().optional().max(100),
    systemAffected: Joi.string().optional().max(200),
    metadata: Joi.object().optional(),
  }),
};

export const MalwareReportSchemas = {
  create: Joi.object({
    malwareType: Joi.string().optional().max(100),
    infectedDeviceType: Joi.string().optional().max(100),
    operatingSystem: Joi.string().optional().max(100),
    detectionMethod: Joi.string().optional().max(200),
    location: Joi.string().optional().max(200),
    fileName: Joi.string().optional().max(200),
    name: Joi.string().optional().max(100),
    systemAffected: Joi.string().optional().max(200),
    alertSeverityLevel: Joi.string().optional().max(50),
  }),

  update: Joi.object({
    malwareType: Joi.string().optional().max(100),
    infectedDeviceType: Joi.string().optional().max(100),
    operatingSystem: Joi.string().optional().max(100),
    detectionMethod: Joi.string().optional().max(200),
    location: Joi.string().optional().max(200),
    fileName: Joi.string().optional().max(200),
    name: Joi.string().optional().max(100),
    systemAffected: Joi.string().optional().max(200),
    alertSeverityLevel: Joi.string().optional().max(50),
    status: Joi.string().valid('pending', 'submitted', 'processed', 'resolved').optional(),
  }),
};

export const UserSchemas = {
  update: Joi.object({
    username: Joi.string().optional().min(3).max(50),
    email: Joi.string().email().optional(),
  }),
};

export const QuerySchemas = {
  pagination: Joi.object({
    page: Joi.number().integer().min(1).optional().default(1),
    limit: Joi.number().integer().min(1).max(100).optional().default(10),
    sortBy: Joi.string().optional(),
    sortOrder: Joi.string().valid('asc', 'desc').optional().default('desc'),
  }),

  period: Joi.object({
    period: Joi.string().valid('1D', '7D', '30D', '90D').optional().default('7D'),
  }),
}; 