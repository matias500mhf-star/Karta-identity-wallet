import { Controller, Delete, Param, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { ShareService } from './share.service';

@Controller('documents')
@UseGuards(AuthGuard)
export class ShareController {
  constructor(private readonly shares: ShareService) {}

  @Post(':id/share')
  create(@Req() request: { user: { sub: string } }, @Param('id') documentId: string) {
    return this.shares.create(request.user.sub, documentId);
  }

  @Delete('/shares/:shareId')
  revoke(@Req() request: { user: { sub: string } }, @Param('shareId') shareId: string) {
    return this.shares.revoke(request.user.sub, shareId);
  }
}
