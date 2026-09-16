import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TokenService } from './token.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokens: TokenService, private readonly prisma: PrismaService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const header = request.headers.authorization;
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) throw new UnauthorizedException();
    const payload = this.tokens.verifyAccessToken(header.slice(7));
    if (typeof payload.sid !== 'string' || !/^[0-9a-f-]{36}$/i.test(payload.sid)) throw new UnauthorizedException();
    const session = await this.prisma.authSession.findFirst({ where: {
      id: payload.sid, userId: payload.sub, expiresAt: { gt: new Date() }, user: { status: 'ACTIVE' },
    }});
    if (!session) throw new UnauthorizedException();
    request.user = { sub: payload.sub, email: payload.email, sid: payload.sid };
    return true;
  }
}
