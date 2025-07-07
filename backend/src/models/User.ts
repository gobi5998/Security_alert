import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  username: string;
  email: string;
  password: string;
  provider?: 'local' | 'google' | 'facebook';
  createdAt: Date;
}

const UserSchema = new Schema<IUser>({
  username: { type: String, required: true, unique: true },
  email:    { type: String, required: true, unique: true },
  password: { type: String, required: true },
  provider: { type: String, enum: ['local', 'google', 'facebook'], default: 'local' },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model<IUser>('User', UserSchema);

export interface IUserResponse {
  id: string;
  username: string;
  email: string;
  createdAt: Date;
}

export interface ILoginRequest {
  username: string;
  password: string;
}

export interface IRegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface ILoginResponse {
  user: IUserResponse;
  token: string;
  message: string;
}

export interface IRegisterResponse {
  user: IUserResponse;
  token: string;
  message: string;
}