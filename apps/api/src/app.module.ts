import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { BackupsModule } from './backups/backups.module';
import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { DocumentsModule } from './documents/documents.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [DatabaseModule, AuthModule, BackupsModule, HealthModule,
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }]),
    ...(process.env.ENABLE_LEGACY_DOCUMENTS === 'true' ? [DocumentsModule] : [])],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
