import { Request, Response } from 'express';
import ScamReport from '../models/scamReport';
import path from 'path';
import fs from 'fs';

// Create a new scam report
export const createScamReport = async (req: Request, res: Response) => {
  try {
    console.log('📥 Received report data:', req.body);
    console.log('📁 Files received:', req.files);

    // Extract file paths from request
    const screenshotPaths: string[] = [];
    const documentPaths: string[] = [];

    // Handle uploaded files
    if (req.files && Array.isArray(req.files)) {
      for (const file of req.files as any[]) {
        const filePath = file.path;
        
        // Categorize files based on field name
        if (file.fieldname === 'screenshots') {
          screenshotPaths.push(filePath);
        } else if (file.fieldname === 'documents') {
          documentPaths.push(filePath);
        }
      }
    }

    // Parse file paths from form fields if they exist
    if (req.body.screenshotPaths) {
      try {
        const parsedScreenshots = JSON.parse(req.body.screenshotPaths);
        screenshotPaths.push(...parsedScreenshots);
      } catch (e) {
        console.log('Error parsing screenshot paths:', e);
      }
    }

    if (req.body.documentPaths) {
      try {
        const parsedDocuments = JSON.parse(req.body.documentPaths);
        documentPaths.push(...parsedDocuments);
      } catch (e) {
        console.log('Error parsing document paths:', e);
      }
    }

    // Create report object
    const reportData = {
      reportId: req.body.reportId, // Flutter-generated ID
      title: req.body.title,
      description: req.body.description,
      type: req.body.type,
      severity: req.body.severity,
      date: new Date(req.body.date),
      phone: req.body.phone || '',
      email: req.body.email || '',
      website: req.body.website || '',
      screenshotPaths: screenshotPaths.length > 0 ? screenshotPaths : undefined,
      documentPaths: documentPaths.length > 0 ? documentPaths : undefined,
    };

    console.log('💾 Saving report with data:', reportData);

    // Check for duplicate reports using reportId
    let existingReport = null;
    if (reportData.reportId) {
      existingReport = await ScamReport.findOne({ reportId: reportData.reportId });
    }
    
    // Fallback: Check for duplicate reports (same title, description, type, and date within 1 minute)
    if (!existingReport) {
      const oneMinuteAgo = new Date(new Date(reportData.date).getTime() - 60000);
      const oneMinuteLater = new Date(new Date(reportData.date).getTime() + 60000);
      
      existingReport = await ScamReport.findOne({
        title: reportData.title,
        description: reportData.description,
        type: reportData.type,
        date: {
          $gte: oneMinuteAgo,
          $lte: oneMinuteLater
        }
      });
    }

    if (existingReport) {
      console.log('🔄 Found existing report, updating:', existingReport._id);
      
      // Update the existing report with new data
      existingReport.severity = reportData.severity;
      existingReport.phone = reportData.phone;
      existingReport.email = reportData.email;
      existingReport.website = reportData.website;
      
      // Merge file paths
      if (reportData.screenshotPaths) {
        existingReport.screenshotPaths = [
          ...(existingReport.screenshotPaths || []),
          ...reportData.screenshotPaths
        ];
      }
      if (reportData.documentPaths) {
        existingReport.documentPaths = [
          ...(existingReport.documentPaths || []),
          ...reportData.documentPaths
        ];
      }
      
      await existingReport.save();
      console.log('✅ Report updated successfully:', existingReport._id);
      res.status(200).json(existingReport);
    } else {
      // Create new report
      const report = new ScamReport(reportData);
      await report.save();
      
      console.log('✅ New report saved successfully:', report._id);
      res.status(201).json(report);
    }
  } catch (err) {
    console.error('❌ Error creating report:', err);
    res.status(400).json({ error: (err as Error).message });
  }
};

// Get all scam reports
export const getAllScamReports = async (_req: Request, res: Response) => {
  try {
    const reports = await ScamReport.find().sort({ date: -1 });
    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
};
