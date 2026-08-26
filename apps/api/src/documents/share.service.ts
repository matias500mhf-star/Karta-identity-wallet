import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { ShareTokenService } from './share-token.service';

@Injectable()
export class ShareService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly shareTokens: ShareTokenService,
  ) {}

  async create(userId: string, documentId: string, expiresInMinutes = 15) {
    const document = await this.prisma.document.findFirst({ where: { id: documentId, userId }, select: { id: true } });
    if (!document) throw new NotFoundException('Document not found');
    if (expiresInMinutes < 1 || expiresInMinutes > 1440) throw new Error('Share expiry must be between 1 minute and 24 hours');

    const { token, hash } = this.shareTokens.generate();
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60_000);
    const share = await this.prisma.documentShare.create({
      data: { documentId, createdById: userId, tokenHash: hash, expiresAt },
      select: { id: true, expiresAt: true },
    });
    return { id: share.id, token, expiresAt: share.expiresAt };
  }

  async revoke(userId: string, shareId: string) {
    const share = await this.prisma.documentShare.findFirst({ where: { id: shareId, createdById: userId }, select: { id: true, revokedAt: true } });
    if (!share) throw new NotFoundException('Share not found');
    if (share.revokedAt) return { id: share.id, revoked: true };

    await this.prisma.documentShare.update({ where: { id: share.id }, data: { revokedAt: new Date() } });
    return { id: share.id, revoked: true };
  }
}
