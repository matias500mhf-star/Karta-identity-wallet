"""Check Android APK update prerequisites without installing or uploading files.

Usage: python scripts/check_android_update.py previous.apk candidate.apk
Requires Android SDK build-tools (apksigner and aapt).
This conservative check does not support signing-key rotation or prove data migration.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def tool(name):
    suffix = '.bat' if os.name == 'nt' and name == 'apksigner' else '.exe' if os.name == 'nt' else ''
    located = shutil.which(name + suffix)
    if located:
        return located
    sdk = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
    if sdk:
        candidates = list((Path(sdk) / 'build-tools').glob('*/' + name + suffix))
        candidates.sort(key=lambda p: tuple(int(n) for n in re.findall(r'\d+', p.parent.name)), reverse=True)
        if candidates:
            return str(candidates[0])
    raise ValueError(f'Falta {name}: instale Android SDK build-tools e configure ANDROID_HOME ou PATH.')


def inspect(apk, signer, aapt):
    if not apk.is_file():
        raise ValueError(f'APK não encontrado: {apk.name}')
    signed = subprocess.run([signer, 'verify', '--print-certs', str(apk.resolve())],
                            capture_output=True, text=True, check=True).stdout
    certificates = set(re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]{64})\s*$', signed, re.M))
    if not certificates:
        raise ValueError('Não foi possível identificar os certificados do APK.')
    badging = subprocess.run([aapt, 'dump', 'badging', str(apk.resolve())],
                             capture_output=True, text=True, check=True).stdout
    package = re.search(r"^package: name='([^']+)' versionCode='(\d+)'", badging, re.M)
    if not package:
        raise ValueError('Não foi possível identificar o pacote e a versão do APK.')
    return package[1], int(package[2]), {c.lower() for c in certificates}


def incompatibilities(previous, candidate):
    reasons = []
    if previous[0] != candidate[0]:
        reasons.append('O identificador da aplicação mudou.')
    if previous[2] != candidate[2]:
        reasons.append('Os certificados de assinatura são diferentes; é necessária revisão da assinatura.')
    if candidate[1] <= previous[1]:
        reasons.append('O versionCode novo deve ser superior ao anterior.')
    return reasons


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('previous', type=Path)
    parser.add_argument('candidate', type=Path)
    args = parser.parse_args()
    try:
        signer, aapt = tool('apksigner'), tool('aapt')
        reasons = incompatibilities(inspect(args.previous, signer, aapt), inspect(args.candidate, signer, aapt))
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'VERIFICAÇÃO INCONCLUSIVA: {error}', file=sys.stderr)
        return 2
    if reasons:
        print('ATUALIZAÇÃO BLOQUEADA NESTA VERIFICAÇÃO:')
        for reason in reasons:
            print('- ' + reason)
        print('Não desinstale a carteira para contornar o problema. Preserve o original e confirme um backup restaurável.')
        return 1
    print('Pacote, certificado e incremento de versão compatíveis.')
    print('Falta testar a atualização e a preservação dos documentos num dispositivo de testes. Não é uma aprovação comercial.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
