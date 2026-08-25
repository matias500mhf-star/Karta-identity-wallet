import { BadRequestException, Injectable } from '@nestjs/common';
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';

@Injectable()
export class DocumentCryptoService {
  private readonly algorithm = 'aes-256-gcm';

  private getKey(): Buffer {
    const secret = process.env.DOCUMENT_ENCRYPTION_KEY;
    if (!secret) throw new Error('DOCUMENT_ENCRYPTION_KEY is not configured');
    return createHash('sha256').update(secret).digest();
  }

  encrypt(input: Buffer) {
    const iv = randomBytes(12);
    const cipher = createCipheriv(this.algorithm, this.getKey(), iv);
    const ciphertext = Buffer.concat([cipher.update(input), cipher.final()]);
    const tag = cipher.getAuthTag();
    return {
      ciphertext,
      iv: iv.toString('base64url'),
      authTag: tag.toString('base64url'),
      algorithm: this.algorithm,
    };
  }

  decrypt(ciphertext: Buffer, iv: string, authTag: string) {
    try {
      const decipher = createDecipheriv(this.algorithm, this.getKey(), Buffer.from(iv, 'base64url'));
      decipher.setAuthTag(Buffer.from(authTag, 'base64url'));
      return Buffer.concat([decipher.update(ciphertext), decipher.final()]);
    } catch {
      throw new BadRequestException('Unable to decrypt document');
    }
  }
}
