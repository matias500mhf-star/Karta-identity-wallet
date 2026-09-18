import { Body, Controller, Delete, Headers, Post, Req, UseGuards, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { timingSafeEqual, createHash } from 'node:crypto';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';
import { AuthGuard } from './auth.guard';
import { PrismaService } from '../database/prisma.service';
import { PasswordService } from './password.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ACCESS_TOKEN_TTL_SECONDS } from './auth.constants';
import { IsString, MaxLength, MinLength } from 'class-validator';

class DeleteAccountDto {
  @IsString() @MinLength(1) @MaxLength(256) password!: string;
}
@Controller('auth')
@Throttle({ default: { limit: 5, ttl: 60000 } })
export class AuthController {
  constructor(private readonly auth: AuthService, private readonly tokens: TokenService,
    private readonly prisma: PrismaService, private readonly passwords: PasswordService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto, @Headers('x-karta-invite') invite?: string) {
    const expected = process.env.BETA_INVITE_CODE;
    const digest = (value: string) => createHash('sha256').update(value).digest();
    if (!expected || !invite || invite.length > 256 || !timingSafeEqual(digest(invite), digest(expected))) {
      throw new ForbiddenException('O registo está limitado a convidados da beta.');
    }
    return this.auth.register(dto);
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const user = await this.auth.validateCredentials(dto);
    // Bounded retention; sessions are short-lived and never refreshed silently.
    await this.prisma.authSession.deleteMany({ where: { userId: user.id, expiresAt: { lte: new Date() } } });
    const session = await this.prisma.authSession.create({ data: {
      userId: user.id, expiresAt: new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000),
    }});
    return { tokenType: 'Bearer', accessToken: this.tokens.issueAccessToken(user.id, user.email, session.id), expiresIn: ACCESS_TOKEN_TTL_SECONDS };
  }

  @Post('logout') @UseGuards(AuthGuard)
  async logout(@Req() req: { user: { sub: string; sid: string } }) {
    await this.prisma.authSession.deleteMany({ where: { id: req.user.sid, userId: req.user.sub } });
    return { loggedOut: true };
  }

  @Delete('account') @UseGuards(AuthGuard)
  async remove(@Req() req: { user: { sub: string } }, @Body() dto: DeleteAccountDto) {
    const user = await this.prisma.user.findUnique({ where: { id: req.user.sub } });
    if (!user || !await this.passwords.verify(dto.password, user.passwordHash)) throw new UnauthorizedException();
    await this.prisma.user.delete({ where: { id: user.id } });
    return { deleted: true };
  }
}
