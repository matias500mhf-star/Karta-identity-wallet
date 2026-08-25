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

    const { token, hash } = this.shareTokens.generate();
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60_000);

    const share = await this.prisma.documentShare.create({
      data: { documentId, createdById: userId, tokenHash: hash, expiresAt },
      select: { id: true, expiresAt: true },
    });

    return { id: share.id, token, expiresAt: share.expiresAt };
  }
}
