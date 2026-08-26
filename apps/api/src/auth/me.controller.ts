import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from './auth.guard';

@Controller('me')
export class MeController {
  @Get()
  @UseGuards(AuthGuard)
  getMe(@Req() request: { user: { sub: string; email: string } }) {
    return {
      id: request.user.sub,
      email: request.user.email,
    };
  }
}
