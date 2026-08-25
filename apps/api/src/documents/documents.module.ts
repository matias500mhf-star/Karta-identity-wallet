import { Module } from '@nestjs/common';
import { DocumentsController } from './documents.controller';
import { DocumentsService } from './documents.service';
import { AuthGuard } from '../auth/auth.guard';

@Module({
  controllers: [DocumentsController],
  providers: [DocumentsService, AuthGuard],
})
export class DocumentsModule {}
