import { Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { ShareService } from './share.service';

@Controller()
export class ShareController {
  constructor(private readonly shares: ShareService) {}

  @Post('documents/:id/share')
  @UseGuards(AuthGuard)
  create(@Req() request: { user: { sub: string } }, @Param('id') documentId: string) {
    return this.shares.create(request.user.sub, documentId);
  }

  @Delete('documents/shares/:shareId')
  @UseGuards(AuthGuard)
  revoke(@Req() request: { user: { sub: string } }, @Param('shareId') shareId: string) {
    return this.shares.revoke(request.user.sub, shareId);
  }

  @Get('share/:token')
  resolve(@Param('token') token: string) {
    return this.shares.resolve(token);
  }
}
