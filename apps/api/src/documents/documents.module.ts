import { Module } from '@nestjs/common';
import { DocumentsController } from './documents.controller';
import { ShareController } from './share.controller';
import { DocumentsService } from './documents.service';
import { AuthGuard } from '../auth/auth.guard';
import { FileSecurityService } from './file-security.service';
import { DocumentCryptoService } from './document-crypto.service';
import { AuditService } from './audit.service';
import { ShareService } from './share.service';
import { ShareTokenService } from './share-token.service';

@Module({
  controllers: [DocumentsController, ShareController],
  providers: [
    DocumentsService,
    AuthGuard,
    FileSecurityService,
    DocumentCryptoService,
    AuditService,
    ShareService,
    ShareTokenService,
  ],
  exports: [DocumentCryptoService, ShareService],
})
export class DocumentsModule {}
