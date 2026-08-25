import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { createHmac } from 'node:crypto';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly secret = process.env.JWT_ACCESS_SECRET ?? 'development-access-secret';

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ headers: Record<string, string | undefined>; user?: { sub: string; email: string } }>();
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthorizedException('Missing access token');

    const token = header.slice(7);
    const [body, signature] = token.split('.');
    if (!body || !signature) throw new UnauthorizedException('Invalid access token');

    const expected = createHmac('sha256', this.secret).update(body).digest('base64url');
    if (signature !== expected) throw new UnauthorizedException('Invalid access token');

    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as { sub?: string; email?: string; type?: string; exp?: number };
    if (payload.type !== 'access' || !payload.sub || !payload.email || !payload.exp || payload.exp <= Math.floor(Date.now() / 1000)) {
      throw new UnauthorizedException('Expired or invalid access token');
    }

    request.user = { sub: payload.sub, email: payload.email };
    return true;
  }
}
