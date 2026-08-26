import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { MeController } from './me.controller';
import { AuthService } from './auth.service';
import { PasswordService } from './password.service';
import { TokenService } from './token.service';
import { AuthGuard } from './auth.guard';

@Module({
  controllers: [AuthController, MeController],
  providers: [AuthService, PasswordService, TokenService, AuthGuard],
  exports: [AuthService, PasswordService, TokenService, AuthGuard],
})
export class AuthModule {}
