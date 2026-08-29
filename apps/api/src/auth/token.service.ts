import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { ACCESS_TOKEN_TTL_SECONDS, REFRESH_TOKEN_TTL_SECONDS } from './auth.constants';

export interface AccessTokenPayload {
  sub: string;
  email: string;
  type: 'access';
  iat: number;
  exp: number;
}

export interface RefreshTokenPayload {
  sub: string;
  type: 'refresh';
  iat: number;
  exp: number;
  nonce: string;
}

@Injectable()
export class TokenService {
  private get accessSecret(): string {
    const secret = process.env.JWT_ACCESS_SECRET;
    if (!secret || secret.length < 32) throw new Error('JWT_ACCESS_SECRET must be configured with at least 32 characters');
    return secret;
  }

  private get refreshSecret(): string {
    const secret = process.env.JWT_REFRESH_SECRET;
    if (!secret || secret.length < 32) throw new Error('JWT_REFRESH_SECRET must be configured with at least 32 characters');
    return secret;
  }

  issueAccessToken(userId: string, email: string): string {
    const now = Math.floor(Date.now() / 1000);
    const payload: AccessTokenPayload = { sub: userId, email, type: 'access', iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS };
    return this.sign(payload, this.accessSecret);
  }

  issueRefreshToken(userId: string): string {
    const now = Math.floor(Date.now() / 1000);
    const payload: RefreshTokenPayload = { sub: userId, type: 'refresh', iat: now, exp: now + REFRESH_TOKEN_TTL_SECONDS, nonce: randomBytes(16).toString('hex') };
    return this.sign(payload, this.refreshSecret);
  }

  verifyAccessToken(token: string): AccessTokenPayload {
    return this.verify<AccessTokenPayload>(token, this.accessSecret, 'access');
  }

  verifyRefreshToken(token: string): RefreshTokenPayload {
    return this.verify<RefreshTokenPayload>(token, this.refreshSecret, 'refresh');
  }

  private sign(payload: Record<string, unknown>, secret: string): string {
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = createHmac('sha256', secret).update(body).digest('base64url');
    return `${body}.${signature}`;
  }

  private verify<T extends { type?: string; sub?: string; exp?: number }>(token: string, secret: string, expectedType: string): T {
    const [body, signature] = token.split('.');
    if (!body || !signature) throw new UnauthorizedException('Invalid token');
    const expected = createHmac('sha256', secret).update(body).digest('base64url');
    const a = Buffer.from(signature);
    const b = Buffer.from(expected);
    if (a.length !== b.length || !timingSafeEqual(a, b)) throw new UnauthorizedException('Invalid token');
    let payload: T;
    try {
      payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as T;
    } catch {
      throw new UnauthorizedException('Invalid token');
    }
    if (payload.type !== expectedType || !payload.sub || !payload.exp || payload.exp <= Math.floor(Date.now() / 1000)) {
      throw new UnauthorizedException('Expired or invalid token');
    }
    return payload;
  }
}
