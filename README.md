# ðŸ–¥ï¸ ProScan â€” DiagnÃ³stico do Windows

Ferramenta de diagnÃ³stico para Windows em **PowerShell puro**, sem instalaÃ§Ã£o de dependÃªncias.  
Desenvolvida para suporte de TI em ambientes corporativos â€” somente leitura, nÃ£o altera nenhuma configuraÃ§Ã£o.

---

## âœ¨ Funcionalidades

| OpÃ§Ã£o | O que verifica |
|-------|---------------|
| `[1]` DiagnÃ³stico completo | Executa todas as seÃ§Ãµes abaixo |
| `[2]` Identidade e BIOS | Computador, usuÃ¡rio, domÃ­nio, fabricante, serial, versÃ£o do BIOS, **Ãºltimo login** |
| `[3]` Hardware e discos | CPU com **% de uso atual**, RAM usada/total com barra visual, discos com **alerta crÃ­tico em vermelho** (<10% livre) |
| `[4]` Rede e internet | DomÃ­nio corporativo, gateway, ping 1.1.1.1 / 8.8.8.8, DNS, adaptadores de rede |
| `[5]` SaÃºde do sistema | Uptime, **status do RDP**, serviÃ§os essenciais, **atualizaÃ§Ãµes pendentes do Windows**, erros no Event Log |
| `[6]` Programas recentes | Ãšltimos 15 programas instalados com data |
| `[7]` Buscar mÃ¡quina na rede | Ping, DNS, consulta CIM/WMI remota completa: **usuÃ¡rio logado**, **RDP remoto**, discos, rede, serviÃ§os e programas |

---

## ðŸŽ¯ Diferenciais

- **Spinner animado** em todas as operaÃ§Ãµes lentas â€” o usuÃ¡rio sabe que estÃ¡ processando, nÃ£o travado
- **Interface visual** com caixas `â•”â•â•â•â•—` centralizadas e cores por status (verde/amarelo/vermelho)
- **Disco crÃ­tico** destacado em vermelho (<10% livre) ou amarelo (<20%)
- **Consulta remota completa** via CIM/WMI com timeout â€” nÃ£o trava em mÃ¡quinas inacessÃ­veis
- **Zero dependÃªncias** â€” funciona em qualquer Windows com PowerShell 5.1+

---

## ðŸš€ Como usar

### InstalaÃ§Ã£o
1. Clone ou baixe a pasta
2. Clique com o botÃ£o direito em `Install-ProScanShortcut.ps1` â†’ **Executar com PowerShell**
3. O atalho **ProScan** serÃ¡ criado na Ãrea de Trabalho

### ExecuÃ§Ã£o direta
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProScan\ProScan.ps1"
```

---

## ðŸ“‹ Requisitos

- Windows 10 / 11
- PowerShell 5.1 (jÃ¡ incluso no Windows)
- Para consulta remota `[7]`: WMI/CIM liberado na mÃ¡quina alvo e conta com permissÃ£o de administrador

---

## ðŸ”’ SeguranÃ§a

O ProScan opera **somente em modo de leitura**. NÃ£o reinicia serviÃ§os, nÃ£o altera configuraÃ§Ãµes e nÃ£o instala nada.

---

## ðŸ“ Arquivos

```
ProScan/
â”œâ”€â”€ ProScan.ps1                  # Script principal
â”œâ”€â”€ Install-ProScanShortcut.ps1  # Cria atalho na Ãrea de Trabalho
â””â”€â”€ README.md
```

---

## ðŸ“Œ VersÃ£o

**v2.2** â€” 22/10/2026
