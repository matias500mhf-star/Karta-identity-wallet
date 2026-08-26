import { BadRequestException, Injectable } from '@nestjs/common';
import { createHash, randomUUID } from 'node:crypto';

const ALLOWED_TYPES = new Set(['application/pdf', 'image/jpeg', 'image/png']);
const MAX_BYTES = 15 * 1024 * 1024;

@Injectable()
export class FileSecurityService {
  validate(contentType: string, size: number) {
    if (!ALLOWED_TYPES.has(contentType)) {
      throw new BadRequestException('Unsupported document type');
    }
    if (size <= 0 || size > MAX_BYTES) {
      throw new BadRequestException('Document exceeds the 15 MB limit');
    }
  }

  createStorageKey(userId: string, originalName: string) {
    const safeName = originalName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(-120);
    const hash = createHash('sha256').update(`${userId}:${randomUUID()}`).digest('hex');
    return `users/${userId}/documents/${hash}-${safeName}`;
  }
}
