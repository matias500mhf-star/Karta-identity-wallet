import { Module } from '@nestjs/common';
import { DocumentsController } from './documents.controller';
import { DocumentsService } from './documents.service';
import { AuthGuard } from '../auth/auth.guard';
import { FileSecurityService } from './file-security.service';
import { DocumentCryptoService } from './document-crypto.service';

@Module({
  controllers: [DocumentsController],
  providers: [DocumentsService, AuthGuard, FileSecurityService, DocumentCryptoService],
  exports: [DocumentCryptoService],
})
export class DocumentsModule {}
