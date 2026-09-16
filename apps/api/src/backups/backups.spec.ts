import { validateEnvelope } from './backups.service';
import { TokenService } from '../auth/token.service';
import { randomBytes } from 'node:crypto';
const envelope = () => Buffer.from(JSON.stringify({ format: 'karta-backup', version: 1, salt: randomBytes(16).toString('base64'), nonce: randomBytes(12).toString('base64'), mac: randomBytes(16).toString('base64'), ciphertext: randomBytes(64).toString('base64') }));
describe('encrypted backup boundary', () => {
  it('accepts only the versioned ciphertext envelope', () => {
    expect(() => validateEnvelope(envelope())).not.toThrow();
    expect(() => validateEnvelope(Buffer.from('{"passport":"private"}'))).toThrow();
    const data = JSON.parse(envelope().toString()); data.password = 'never send';
    expect(() => validateEnvelope(Buffer.from(JSON.stringify(data)))).toThrow();
    delete data.password; data.mac = 'AA==';
    expect(() => validateEnvelope(Buffer.from(JSON.stringify(data)))).toThrow();
  });
  it('rejects appended token segments and modified signatures', () => {
    process.env.JWT_ACCESS_SECRET = 'test-only-secret-'.repeat(4);
    const tokens = new TokenService();
    const token = tokens.issueAccessToken('test', 'test@example.invalid', '00000000-0000-0000-0000-000000000000');
    expect(tokens.verifyAccessToken(token).sub).toBe('test');
    expect(() => tokens.verifyAccessToken(token + '.ignored')).toThrow();
    expect(() => tokens.verifyAccessToken('x' + token)).toThrow();
  });
});
