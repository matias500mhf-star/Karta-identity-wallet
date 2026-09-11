import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { CreateDocumentInput, DocumentsService } from './documents.service';

@Controller('documents')
@UseGuards(AuthGuard)
export class DocumentsController {
  constructor(private readonly documents: DocumentsService) {}

  @Get()
  list(@Req() request: { user: { sub: string } }) {
    return this.documents.listForUser(request.user.sub);
  }

  @Get(':id')
  get(@Req() request: { user: { sub: string } }, @Param('id') id: string) {
    return this.documents.getForUser(request.user.sub, id);
  }

  @Post()
  create(
    @Req() request: { user: { sub: string } },
    @Body() body: CreateDocumentInput,
  ) {
    return this.documents.createForUser(request.user.sub, body);
  }
}
