import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly tokens: TokenService,
  ) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const user = await this.auth.validateCredentials(dto);
    return {
      tokenType: 'Bearer',
      accessToken: this.tokens.issueAccessToken(user.id, user.email),
      refreshToken: this.tokens.issueRefreshToken(user.id),
    };
  }
}
