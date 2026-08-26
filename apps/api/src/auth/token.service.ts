import { Injectable } from '@nestjs/common';
import { createHmac, randomBytes } from 'node:crypto';
import { ACCESS_TOKEN_TTL_SECONDS, REFRESH_TOKEN_TTL_SECONDS } from './auth.constants';

export interface AccessTokenPayload {
  sub: string;
  email: string;
  type: 'access';
  iat: number;
  exp: number;
}

@Injectable()
export class TokenService {
  private readonly accessSecret = process.env.JWT_ACCESS_SECRET ?? 'development-access-secret';
  private readonly refreshSecret = process.env.JWT_REFRESH_SECRET ?? 'development-refresh-secret';

  issueAccessToken(userId: string, email: string): string {
    const now = Math.floor(Date.now() / 1000);
    const payload = { sub: userId, email, type: 'access', iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS };
    return this.sign(payload, this.accessSecret);
  }

  issueRefreshToken(userId: string): string {
    const now = Math.floor(Date.now() / 1000);
    const payload = { sub: userId, type: 'refresh', iat: now, exp: now + REFRESH_TOKEN_TTL_SECONDS, nonce: randomBytes(16).toString('hex') };
    return this.sign(payload, this.refreshSecret);
  }

  private sign(payload: Record<string, unknown>, secret: string): string {
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = createHmac('sha256', secret).update(body).digest('base64url');
    return `${body}.${signature}`;
  }
}
