import { DocumentType } from '@prisma/client';
import { IsEnum, IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateDocumentDto {
  @IsEnum(DocumentType)
  type!: DocumentType;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  issuer?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  documentNumber?: string;

  @IsOptional()
  @IsISO8601()
  expiresAt?: string;

  @IsString()
  @MinLength(1)
  storageKey!: string;

  @IsString()
  @MinLength(64)
  contentHash!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  algorithm?: string;

  @IsString()
  @MinLength(16)
  iv!: string;

  @IsString()
  @MinLength(16)
  authTag!: string;
}
