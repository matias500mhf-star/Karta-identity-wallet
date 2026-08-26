import { Injectable } from '@nestjs/common';
import { randomBytes, scrypt as nodeScrypt, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(nodeScrypt);

@Injectable()
export class PasswordService {
  private readonly keyLength = 64;

  async hash(password: string): Promise<string> {
    const salt = randomBytes(16).toString('hex');
    const derivedKey = (await scrypt(password, salt, this.keyLength)) as Buffer;
    return `scrypt$${salt}$${derivedKey.toString('hex')}`;
  }

  async verify(password: string, encoded: string): Promise<boolean> {
    const [algorithm, salt, hash] = encoded.split('$');
    if (algorithm !== 'scrypt' || !salt || !hash) return false;

    const expected = Buffer.from(hash, 'hex');
    const actual = (await scrypt(password, salt, this.keyLength)) as Buffer;
    return expected.length === actual.length && timingSafeEqual(expected, actual);
  }
}
