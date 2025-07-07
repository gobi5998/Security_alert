import { Schema, model, Document } from 'mongoose';

export interface IScamReport extends Document {
  reportId?: string; // Flutter-generated ID for deduplication
  title: string;
  description: string;
  type: string;
  severity: string;
  date: Date;
  phone?: string;
  email?: string;
  website?: string;
  screenshotPaths?: string[];
  documentPaths?: string[];
}

const ScamReportSchema = new Schema<IScamReport>({
  reportId: { type: String, unique: true, sparse: true }, // Flutter-generated ID
  title: { type: String, required: true },
  description: { type: String, required: true },
  type: { type: String, required: true },
  severity: { type: String, required: true },
  date: { type: Date, required: true },
  phone: { type: String },
  email: { type: String },
  website: { type: String },
  screenshotPaths: [{ type: String }],
  documentPaths: [{ type: String }],
});

export default model<IScamReport>('ScamReport', ScamReportSchema);
