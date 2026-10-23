# ProScan â€” DiagnÃ³stico do Windows

> Ferramenta de diagnÃ³stico para ambientes Windows corporativos, desenvolvida em **PowerShell puro**, sem necessidade de instalaÃ§Ã£o de dependÃªncias externas.

---

## Sobre o projeto

O **ProScan** nasceu da necessidade de agilizar o suporte de TI no dia a dia. Em vez de abrir vÃ¡rios painÃ©is do Windows para coletar informaÃ§Ãµes bÃ¡sicas de uma mÃ¡quina, o ProScan centraliza tudo em um Ãºnico terminal â€” com interface visual, cores por status e animaÃ§Ã£o de carregamento para operaÃ§Ãµes demoradas.

Funciona em modo **somente leitura**: nÃ£o altera configuraÃ§Ãµes, nÃ£o reinicia serviÃ§os e nÃ£o instala nenhum componente.

---

## Preview

![ProScan Menu](assets/preview.png)

---

## Funcionalidades

| OpÃ§Ã£o | DescriÃ§Ã£o |
|-------|-----------|
| `[1]` DiagnÃ³stico completo | Executa todas as seÃ§Ãµes em sequÃªncia |
| `[2]` Identidade e BIOS | Nome do computador, usuÃ¡rio, domÃ­nio, fabricante, modelo, serial, versÃ£o do BIOS e Ãºltimo login |
| `[3]` Hardware e discos | Processador com percentual de uso atual, memÃ³ria RAM usada e total com barra visual, discos locais com alerta colorido por espaÃ§o livre |
| `[4]` Rede e internet | DomÃ­nio corporativo, gateway padrÃ£o, teste de conectividade (1.1.1.1 / 8.8.8.8), resoluÃ§Ã£o DNS, adaptadores de rede fÃ­sicos |
| `[5]` SaÃºde do sistema | Tempo ligado (uptime), status do Remote Desktop (RDP), serviÃ§os essenciais do Windows, atualizaÃ§Ãµes pendentes, erros crÃ­ticos no Event Log dos Ãºltimos 7 dias |
| `[6]` Programas recentes | Ãšltimos 15 programas instalados com data de instalaÃ§Ã£o |
| `[7]` Buscar mÃ¡quina na rede | DiagnÃ³stico remoto completo via CIM/WMI: ping, DNS, dados do sistema, usuÃ¡rio(s) logado(s), status do RDP, discos, rede, serviÃ§os e programas instalados |

---

## Destaques tÃ©cnicos

- **Spinner animado** â€” exibido durante operaÃ§Ãµes lentas (consultas de rede, Windows Update, Event Log, acesso remoto) para indicar que o sistema estÃ¡ processando
- **Cores por status** â€” verde para serviÃ§os ativos e conexÃµes bem-sucedidas, amarelo para alertas, vermelho para falhas crÃ­ticas
- **Alerta de disco** â€” amarelo quando o espaÃ§o livre estÃ¡ abaixo de 20%, vermelho abaixo de 10%
- **Consulta remota com timeout** â€” ao buscar uma mÃ¡quina via `[7]`, todas as consultas CIM/WMI tÃªm timeout de 10 segundos, evitando que o script trave em mÃ¡quinas inacessÃ­veis
- **DetecÃ§Ã£o de domÃ­nio corporativo** â€” identifica automaticamente se a mÃ¡quina estÃ¡ ingressada na rede
- **CompatÃ­vel com PowerShell 5.1** â€” presente por padrÃ£o no Windows 10 e 11, sem necessidade de atualizaÃ§Ã£o

---

## PrÃ©-requisitos

- Windows 10 ou Windows 11
- PowerShell 5.1 (jÃ¡ incluso no sistema operacional)
- Para a opÃ§Ã£o `[7]` (busca remota):
  - WMI/CIM habilitado na mÃ¡quina de destino
  - Conta com permissÃ£o de administrador local na mÃ¡quina remota
  - Porta 135 (RPC) liberada no firewall

---

## InstalaÃ§Ã£o

**OpÃ§Ã£o 1 â€” Atalho na Ãrea de Trabalho (recomendado)**

1. Copie a pasta para `C:\ProScan\`
2. Clique com o botÃ£o direito em `Install-ProScanShortcut.ps1`
3. Selecione **Executar com PowerShell**
4. O atalho **ProScan** serÃ¡ criado automaticamente na Ãrea de Trabalho

**OpÃ§Ã£o 2 â€” ExecuÃ§Ã£o direta pelo terminal**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProScan\ProScan.ps1"
```

---

## Estrutura do repositÃ³rio

```
ProScan/
â”œâ”€â”€ ProScan.ps1                  # Script principal
â”œâ”€â”€ Install-ProScanShortcut.ps1  # CriaÃ§Ã£o do atalho na Ãrea de Trabalho
â”œâ”€â”€ assets/
â”‚   â””â”€â”€ menu.svg                 # Preview do menu principal
â””â”€â”€ README.md                    # DocumentaÃ§Ã£o
```

---

## SeguranÃ§a

O ProScan opera exclusivamente em modo de leitura. Nenhuma configuraÃ§Ã£o Ã© alterada, nenhum serviÃ§o Ã© reiniciado e nenhum arquivo externo Ã© baixado ou executado. Todas as consultas utilizam APIs nativas do Windows (CIM, WMI, registro, Event Log).

---

## HistÃ³rico de versÃµes

| VersÃ£o | Data | AlteraÃ§Ãµes |
|--------|------|------------|
| v2.2 | 22/10/2026 | Spinner animado, status do RDP (local e remoto), Ãºltimo login, CPU e RAM em uso, alerta crÃ­tico de disco, atualizaÃ§Ãµes pendentes do Windows, usuÃ¡rio logado remotamente |
| v2.1 | 20/10/2026 | Interface com caixas, menu centralizado, busca remota completa, opÃ§Ã£o `[0]` voltar ao menu |
| v2.0 | 19/10/2026 | VersÃ£o inicial modularizada |

---

## Autor

Desenvolvido por **Renato Moura** â€” TI | EXSA  
[GitHub](https://github.com/Reinattos)
