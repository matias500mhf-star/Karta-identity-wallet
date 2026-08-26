import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async record(userId: string | null, action: string, resource?: string, resourceId?: string) {
    return this.prisma.auditLog.create({
      data: { userId, action, resource, resourceId },
    });
  }
}
