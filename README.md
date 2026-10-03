# AtletaEstoico — App iOS nativo

Mensagens estoicas e de livros para atletas, no momento certo do treino. 100% on-device.

## Status
Estrutura criada em 28/09/2026. Código Swift ainda não iniciado (vem após o gate de validação, ver `docs/Plano_Fase1.md`).

## Como abrir
```bash
brew install xcodegen
cd AtletaEstoico
xcodegen generate
open AtletaEstoico.xcodeproj
```
No Xcode: Target → Signing & Capabilities → confirmar **HealthKit**. HealthKit exige device físico para dados reais (o simulador aceita dados de teste).

## Estrutura
- `PROJECT_CONTEXT.md` — documento mestre (tese, decisões, escopo, arquitetura, riscos)
- `docs/` — plano de execução e documentos de apoio
- `Content/` — biblioteca curada de mensagens + regras de direitos
- `Sources/`, `Tests/`, `Resources/` — app iOS (XcodeGen via `project.yml`)
