import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

export type CreateDocumentInput = {
  type: string;
  title: string;
  issuer?: string;
  documentNumber?: string;
  expiresAt?: string;
  storageKey: string;
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
        type: true,
        title: true,
        issuer: true,
        documentNumber: true,
        expiresAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async getForUser(userId: string, documentId: string) {
    const document = await this.prisma.document.findFirst({
      where: { id: documentId, userId },
      select: {
        id: true,
        type: true,
        title: true,
        issuer: true,
        documentNumber: true,
        expiresAt: true,
        storageKey: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!document) throw new NotFoundException('Document not found');
    return document;
  }

  async createForUser(userId: string, input: CreateDocumentInput) {
    return this.prisma.document.create({
      data: {
        userId,
        type: input.type,
        title: input.title,
        issuer: input.issuer,
        documentNumber: input.documentNumber,
        expiresAt: input.expiresAt ? new Date(input.expiresAt) : undefined,
        storageKey: input.storageKey,
      },
    });
  }
}
