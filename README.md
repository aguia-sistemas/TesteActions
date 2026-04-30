# TesteActions

Projeto simples em .NET para validar pipeline de CI no GitHub Actions.

## Cobertura de Testes

<!-- COVERAGE-START -->
![Coverage](https://img.shields.io/badge/coverage-100.0%25-brightgreen)

| Componente | Cobertura |
|---|---|
| **Total** | **100.0%** (3/3 linhas) |
| `App` | 100.0% |

_Branches: 100.0% — atualizado em 30/04/2026_
<!-- COVERAGE-END -->

> ⚠️ **Importante:** se você alterou código que afeta a cobertura, rode o script abaixo antes de abrir/atualizar o PR. O CI verifica e bloqueia o merge se o README estiver desatualizado.

## Estrutura

```
TesteActions.sln
├── src/App              # Biblioteca
└── tests/App.Tests      # Testes xUnit
```

## Rodar localmente

### Testes simples

```bash
dotnet test
```

### Testes + atualização do README com cobertura

```bash
./scripts/update-readme-coverage.sh
```

O script roda os testes com `coverlet.collector`, calcula a cobertura, e atualiza a seção "Cobertura de Testes" deste README. Depois é só dar `git add README.md && git commit`.

## Opcional
# Test Asana
