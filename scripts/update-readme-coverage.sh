#!/usr/bin/env bash
# scripts/update-readme-coverage.sh
#
# Roda os testes com cobertura e atualiza a seção entre os marcadores
# <!-- COVERAGE-START --> e <!-- COVERAGE-END --> no README.md.
#
# Uso:
#   ./scripts/update-readme-coverage.sh           # roda tudo (testes + atualiza README)
#   ./scripts/update-readme-coverage.sh --skip-tests   # só atualiza README usando coverage existente
#
# Pré-requisitos:
#   - dotnet (.NET 8+ com coverlet.collector instalado nos projetos de teste)
#   - python3 (pra parsear o XML)

set -euo pipefail

SKIP_TESTS=false
COVERAGE_DIR="./coverage"
README="README.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests) SKIP_TESTS=true; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Argumento desconhecido: $1"; exit 1 ;;
  esac
done

# 1. Roda os testes (a menos que --skip-tests)
if [[ "$SKIP_TESTS" == "false" ]]; then
  echo "🧪 Limpando pasta de cobertura..."
  rm -rf "$COVERAGE_DIR"

  echo "🧪 Rodando testes com cobertura..."
  dotnet test \
    --configuration Release \
    --collect:"XPlat Code Coverage" \
    --results-directory "$COVERAGE_DIR"
fi

# 2. Localiza o(s) arquivo(s) de cobertura
mapfile -t COVERAGE_FILES < <(find "$COVERAGE_DIR" -name 'coverage.cobertura.xml' -type f)
if [[ ${#COVERAGE_FILES[@]} -eq 0 ]]; then
  echo "❌ Nenhum arquivo coverage.cobertura.xml encontrado em $COVERAGE_DIR"
  echo "   Rode sem --skip-tests para gerar."
  exit 1
fi

# 3. Mescla com ReportGenerator se houver múltiplos
if [[ ${#COVERAGE_FILES[@]} -gt 1 ]]; then
  echo "📦 Múltiplos arquivos de cobertura — mesclando com ReportGenerator..."
  if ! command -v reportgenerator &> /dev/null; then
    dotnet tool install -g dotnet-reportgenerator-globaltool 2>/dev/null || true
    export PATH="$PATH:$HOME/.dotnet/tools"
  fi
  reportgenerator \
    "-reports:$COVERAGE_DIR/**/coverage.cobertura.xml" \
    "-targetdir:$COVERAGE_DIR/merged" \
    "-reporttypes:Cobertura" > /dev/null
  COVERAGE_FILE="$COVERAGE_DIR/merged/Cobertura.xml"
else
  COVERAGE_FILE="${COVERAGE_FILES[0]}"
fi

echo "📊 Usando cobertura: $COVERAGE_FILE"

# 4. Atualiza README via Python
COVERAGE_FILE="$COVERAGE_FILE" README="$README" python3 <<'PY'
import xml.etree.ElementTree as ET
import os, re
from datetime import datetime, timezone, timedelta

cov_file = os.environ['COVERAGE_FILE']
readme = os.environ['README']

tree = ET.parse(cov_file)
root = tree.getroot()

line_rate = float(root.attrib['line-rate']) * 100
branch_rate = float(root.attrib['branch-rate']) * 100
lines_covered = int(root.attrib['lines-covered'])
lines_valid = int(root.attrib['lines-valid'])

packages = []
for pkg in root.findall('.//package'):
    name = pkg.attrib['name']
    rate = float(pkg.attrib['line-rate']) * 100
    packages.append((name, rate))
packages.sort(key=lambda x: x[1], reverse=True)

if line_rate >= 80:   color = 'brightgreen'
elif line_rate >= 60: color = 'green'
elif line_rate >= 40: color = 'yellow'
elif line_rate >= 20: color = 'orange'
else:                 color = 'red'

br_tz = timezone(timedelta(hours=-3))
today = datetime.now(br_tz).strftime('%d/%m/%Y')

lines = ['<!-- COVERAGE-START -->']
lines.append(f'![Coverage](https://img.shields.io/badge/coverage-{line_rate:.1f}%25-{color})')
lines.append('')
lines.append('| Componente | Cobertura |')
lines.append('|---|---|')
lines.append(f'| **Total** | **{line_rate:.1f}%** ({lines_covered}/{lines_valid} linhas) |')
for name, rate in packages:
    lines.append(f'| `{name}` | {rate:.1f}% |')
lines.append('')
lines.append(f'_Branches: {branch_rate:.1f}% — atualizado em {today}_')
lines.append('<!-- COVERAGE-END -->')
new_section = '\n'.join(lines)

with open(readme, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(r'<!-- COVERAGE-START -->.*?<!-- COVERAGE-END -->', re.DOTALL)
if pattern.search(content):
    new_content = pattern.sub(new_section, content)
else:
    new_content = content.rstrip() + '\n\n## Cobertura de Testes\n\n' + new_section + '\n'

if new_content != content:
    with open(readme, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"✅ README atualizado: cobertura total = {line_rate:.1f}%")
else:
    print(f"✅ README já estava atualizado ({line_rate:.1f}%)")
PY
