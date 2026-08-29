import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { TokenService } from './token.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokens: TokenService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ headers: Record<string, string | undefined>; user?: { sub: string; email: string } }>();
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthorizedException('Missing access token');
    const payload = this.tokens.verifyAccessToken(header.slice(7));
    request.user = { sub: payload.sub, email: payload.email };
    return true;
  }
}
