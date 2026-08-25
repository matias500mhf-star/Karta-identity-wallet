import { Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class ShareService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, documentId: string, expiresInMinutes = 15) {
    const document = await this.prisma.document.findFirst({ where: { id: documentId, userId }, select: { id: true } });
    if (!document) throw new NotFoundException('Document not found');

    const token = randomBytes(32).toString('base64url');
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60_000);

    return this.prisma.documentShare.create({
      data: { documentId, createdById: userId, tokenHash: token, expiresAt },
      select: { id: true, expiresAt: true, tokenHash: true },
    });
  }
}
