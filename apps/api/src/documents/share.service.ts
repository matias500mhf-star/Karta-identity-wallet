import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { ShareTokenService } from './share-token.service';
import { AuditService } from './audit.service';

@Injectable()
export class ShareService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly shareTokens: ShareTokenService,
    private readonly audit: AuditService,
  ) {}

  async create(userId: string, documentId: string, expiresInMinutes = 15) {
    const document = await this.prisma.document.findFirst({ where: { id: documentId, userId }, select: { id: true } });
    if (!document) throw new NotFoundException('Document not found');
    if (expiresInMinutes < 1 || expiresInMinutes > 1440) throw new UnauthorizedException('Share expiry must be between 1 minute and 24 hours');

    const { token, hash } = this.shareTokens.generate();
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60_000);
    const share = await this.prisma.documentShare.create({
      data: { documentId, createdById: userId, tokenHash: hash, expiresAt },
      select: { id: true, expiresAt: true },
    });
    await this.audit.record(userId, 'SHARE_CREATED', 'DocumentShare', share.id);
    return { id: share.id, token, expiresAt: share.expiresAt, qrPayload: `karta://share/${token}` };
  }

  async resolve(token: string) {
    if (!token || token.length < 40) throw new UnauthorizedException('Invalid share token');
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const share = await this.prisma.documentShare.findUnique({
      where: { tokenHash },
      include: { document: { select: { id: true, documentType: true, title: true, issuer: true, documentNumber: true, expiresAt: true, status: true } } },
    });
    if (!share || share.revokedAt || share.expiresAt <= new Date()) throw new UnauthorizedException('Share is expired or revoked');
    await this.audit.record(null, 'SHARE_ACCESSED', 'DocumentShare', share.id);
    return { shareId: share.id, expiresAt: share.expiresAt, document: share.document };
  }

  async revoke(userId: string, shareId: string) {
    const share = await this.prisma.documentShare.findFirst({ where: { id: shareId, createdById: userId }, select: { id: true, revokedAt: true } });
    if (!share) throw new NotFoundException('Share not found');
    if (share.revokedAt) return { id: share.id, revoked: true };
    await this.prisma.documentShare.update({ where: { id: share.id }, data: { revokedAt: new Date() } });
    await this.audit.record(userId, 'SHARE_REVOKED', 'DocumentShare', share.id);
    return { id: share.id, revoked: true };
  }
}
