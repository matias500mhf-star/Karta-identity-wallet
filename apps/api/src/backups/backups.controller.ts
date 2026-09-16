import { BadRequestException, Controller, Delete, Get, Header, HttpException, Put, Req, Res, UseGuards } from '@nestjs/common';
import { IncomingMessage, ServerResponse } from 'node:http';
import { AuthGuard } from '../auth/auth.guard';
import { BackupsService, MAX_BACKUP_BYTES } from './backups.service';
import { Throttle } from '@nestjs/throttler';
type BackupRequest = IncomingMessage & { user: { sub: string } };

@Controller('backups/latest') @UseGuards(AuthGuard)
@Throttle({ default: { limit: 10, ttl: 60000 } })
export class BackupsController {
  constructor(private readonly backups: BackupsService) {}
  @Get('metadata') @Header('Cache-Control', 'no-store')
  metadata(@Req() req: BackupRequest) { return this.backups.metadata(req.user.sub); }

  @Put() @Header('Cache-Control', 'no-store')
  async put(@Req() req: BackupRequest) {
    if (req.headers['content-type']?.split(';')[0] !== 'application/octet-stream') throw new BadRequestException('Envie um backup cifrado.');
    if (Number(req.headers['content-length']) > MAX_BACKUP_BYTES) throw new HttpException('Backup demasiado grande.', 413);
    const chunks: Buffer[] = []; let size = 0;
    for await (const chunk of req) {
      size += chunk.length;
      if (size > MAX_BACKUP_BYTES) throw new HttpException('Backup demasiado grande.', 413);
      chunks.push(Buffer.from(chunk));
    }
    return this.backups.put(req.user.sub, Buffer.concat(chunks));
  }
  @Get()
  async get(@Req() req: BackupRequest, @Res() res: ServerResponse) {
    const row = await this.backups.get(req.user.sub);
    res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Content-Length': row.size,
      'Cache-Control': 'no-store', 'Content-Disposition': 'attachment; filename="karta-backup.kartabackup"',
      'X-Content-SHA256': row.digest });
    res.end(Buffer.from(row.payload));
  }
  @Delete() @Header('Cache-Control', 'no-store')
  remove(@Req() req: BackupRequest) { return this.backups.remove(req.user.sub); }
}
