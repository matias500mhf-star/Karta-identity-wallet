import { Injectable, NotFoundException } from '@nestjs/common';
import { DocumentType } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

export type CreateDocumentInput = {
  type: DocumentType;
  title: string;
  issuer?: string;
  documentNumber?: string;
  expiresAt?: string;
  storageKey: string;
  contentHash: string;
  algorithm?: string;
  iv: string;
  authTag: string;
};

@Injectable()
export class DocumentsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string) {
    return this.prisma.document.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        documentType: true,
        title: true,
        issuer: true,
        documentNumber: true,
        expiresAt: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        versions: { orderBy: { createdAt: 'desc' }, take: 1, select: { id: true, createdAt: true } },
      },
    });
  }

  async getForUser(userId: string, documentId: string) {
    const document = await this.prisma.document.findFirst({
      where: { id: documentId, userId },
      include: { versions: { orderBy: { createdAt: 'desc' } } },
    });
    if (!document) throw new NotFoundException('Document not found');
    return document;
  }

  async createForUser(userId: string, input: CreateDocumentInput) {
    return this.prisma.document.create({
      data: {
        userId,
        documentType: input.type,
        title: input.title,
        issuer: input.issuer,
        documentNumber: input.documentNumber,
        expiresAt: input.expiresAt ? new Date(input.expiresAt) : undefined,
        versions: {
          create: {
            storageKey: input.storageKey,
            contentHash: input.contentHash,
            algorithm: input.algorithm ?? 'aes-256-gcm',
            iv: input.iv,
            authTag: input.authTag,
          },
        },
      },
      include: { versions: true },
    });
  }
}
