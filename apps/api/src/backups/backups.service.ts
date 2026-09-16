import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';

export const MAX_BACKUP_BYTES = 48 * 1024 * 1024;
const meta = { size: true, digest: true, updatedAt: true } as const;
export function validateEnvelope(bytes: Buffer) {
  if (!bytes.length || bytes.length > MAX_BACKUP_BYTES) throw new BadRequestException('Tamanho inválido.');
  let data: Record<string, unknown>;
  try { data = JSON.parse(bytes.toString('utf8')); } catch { throw new BadRequestException('Backup inválido.'); }
  if (!data || Array.isArray(data) || data.format !== 'karta-backup' || data.version !== 1 ||
      Object.keys(data).sort().join(',') !== 'ciphertext,format,mac,nonce,salt,version') throw new BadRequestException('Backup incompatível.');
  for (const [key, expected] of [['salt', 16], ['nonce', 12], ['mac', 16], ['ciphertext', 0]] as const) {
    const value = data[key];
    if (typeof value !== 'string' || !/^[A-Za-z0-9+/]+={0,2}$/.test(value) || value.length % 4 !== 0) throw new BadRequestException('Backup inválido.');
    const decoded = Buffer.from(value, 'base64');
    if (decoded.toString('base64') !== value || (expected ? decoded.length !== expected : decoded.length === 0)) throw new BadRequestException('Backup inválido.');
  }
  // The server cannot authenticate/decrypt the envelope: only the client knows its password.
}
@Injectable()
export class BackupsService {
  constructor(private readonly prisma: PrismaService) {}
  async put(userId: string, bytes: Buffer) {
    validateEnvelope(bytes);
    const data = { payload: new Uint8Array(bytes), size: bytes.length, digest: createHash('sha256').update(bytes).digest('hex') };
    return this.prisma.onlineBackup.upsert({ where: { userId }, create: { userId, ...data }, update: data, select: meta });
  }
  async metadata(userId: string) {
    return this.prisma.onlineBackup.findUnique({ where: { userId }, select: meta });
  }
  async get(userId: string) {
    const row = await this.prisma.onlineBackup.findUnique({ where: { userId } });
    if (!row) throw new NotFoundException('Ainda não existe backup online.');
    return row;
  }
  async remove(userId: string) {
    await this.prisma.onlineBackup.deleteMany({ where: { userId } });
    return { deleted: true };
  }
}
