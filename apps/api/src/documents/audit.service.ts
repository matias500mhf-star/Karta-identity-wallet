import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async record(userId: string, action: string, entityType: string, entityId?: string) {
    return this.prisma.auditLog.create({
      data: { userId, action, entityType, entityId },
    });
  }
}
