# ProScan — Diagnostico do Windows

> Ferramenta de diagnostico para ambientes Windows corporativos, desenvolvida em **PowerShell puro**, sem necessidade de instalacao de dependencias externas.

---

## Sobre o projeto

O **ProScan** nasceu da necessidade de agilizar o suporte de TI no dia a dia. Em vez de abrir varios paineis do Windows para coletar informacoes basicas de uma maquina, o ProScan centraliza tudo em um unico terminal — com interface visual, cores por status e animacao de carregamento para operacoes demoradas.

Funciona em modo **somente leitura**: nao altera configuracoes, nao reinicia servicos e nao instala nenhum componente.

---

## Preview

```
        +================================================================+
        |                                                                |
        |                       P R O S C A N                           |
        |                  Diagnostico do Windows                       |
        |                                                                |
        +================================================================+
        |                                                                |
        |         [1]  Diagnostico completo                              |
        |         [2]  Identidade do computador e BIOS                   |
        |         [3]  Hardware e discos                                 |
        |         [4]  Rede e internet                                   |
        |         [5]  Saude do sistema                                  |
        |         [6]  Programas instalados recentemente                 |
        |         [7]  Buscar maquina na rede                            |
        |                                                                |
        +--------------------------------+-------------------------------+
        |         [0]  Sair                                              |
        +================================================================+

                        Escolha >
```

```
+-- HARDWARE E DISCOS ================================================+
|                                                                      |
|   Processador  :  Intel Core i7-10700 @ 2.90GHz                     |
|   Nucleos      :  8 fisicos / 16 logicos                            |
|   CPU atual    :  12%                                                |
|                                                                      |
|   RAM total    :  15.9 GB                                            |
|   RAM em uso   :  6.2 GB de 15.9 GB  [######....] 39%              |
|                                                                      |
|   Disco C:  :  87.4 GB livres de 237.9 GB  [####......] 37%        |
|   Disco D:  :  4.1 GB livres de 50.0 GB  [##########] 8% !! CRITICO|
|                                                                      |
+======================================================================+
```

---

## Funcionalidades

| Opcao | Descricao |
|-------|-----------|
| `[1]` Diagnostico completo | Executa todas as secoes em sequencia |
| `[2]` Identidade e BIOS | Nome do computador, usuario, dominio, fabricante, modelo, serial, versao do BIOS e ultimo login |
| `[3]` Hardware e discos | Processador com percentual de uso atual, memoria RAM usada e total com barra visual, discos locais com alerta colorido por espaco livre |
| `[4]` Rede e internet | Dominio corporativo, gateway padrao, teste de conectividade (1.1.1.1 / 8.8.8.8), resolucao DNS, adaptadores de rede fisicos |
| `[5]` Saude do sistema | Tempo ligado (uptime), status do Remote Desktop (RDP), servicos essenciais do Windows, atualizacoes pendentes, erros criticos no Event Log dos ultimos 7 dias |
| `[6]` Programas recentes | Ultimos 15 programas instalados com data de instalacao |
| `[7]` Buscar maquina na rede | Diagnostico remoto completo via CIM/WMI: ping, DNS, dados do sistema, usuario(s) logado(s), status do RDP, discos, rede, servicos e programas instalados |

---

## Destaques tecnicos

- **Spinner animado** — exibido durante operacoes lentas (consultas de rede, Windows Update, Event Log, acesso remoto) para indicar que o sistema esta processando
- **Cores por status** — verde para servicos ativos e conexoes bem-sucedidas, amarelo para alertas, vermelho para falhas criticas
- **Alerta de disco** — amarelo quando o espaco livre esta abaixo de 20%, vermelho abaixo de 10%
- **Consulta remota com timeout** — ao buscar uma maquina via `[7]`, todas as consultas CIM/WMI tem timeout de 10 segundos, evitando que o script trave em maquinas inacessiveis
- **Deteccao de dominio corporativo** — identifica automaticamente se a maquina esta ingressada na rede
- **Compativel com PowerShell 5.1** — presente por padrao no Windows 10 e 11, sem necessidade de atualizacao

---

## Pre-requisitos

- Windows 10 ou Windows 11
- PowerShell 5.1 (ja incluso no sistema operacional)
- Para a opcao `[7]` (busca remota):
  - WMI/CIM habilitado na maquina de destino
  - Conta com permissao de administrador local na maquina remota
  - Porta 135 (RPC) liberada no firewall

---

## Instalacao

**Opcao 1 — Atalho na Area de Trabalho (recomendado)**

1. Copie a pasta para `C:\ProScan\`
2. Clique com o botao direito em `Install-ProScanShortcut.ps1`
3. Selecione **Executar com PowerShell**
4. O atalho **ProScan** sera criado automaticamente na Area de Trabalho

**Opcao 2 — Execucao direta pelo terminal**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProScan\ProScan.ps1"
```

---

## Estrutura do repositorio

```
ProScan/
├── ProScan.ps1                  # Script principal
├── Install-ProScanShortcut.ps1  # Criacao do atalho na Area de Trabalho
└── README.md                    # Documentacao
```

---

## Seguranca

O ProScan opera exclusivamente em modo de leitura. Nenhuma configuracao e alterada, nenhum servico e reiniciado e nenhum arquivo externo e baixado ou executado. Todas as consultas utilizam APIs nativas do Windows (CIM, WMI, registro, Event Log).

---

## Historico de versoes

| Versao | Data | Alteracoes |
|--------|------|------------|
| v2.2 | 22/10/2026 | Spinner animado, status do RDP (local e remoto), ultimo login, CPU e RAM em uso, alerta critico de disco, atualizacoes pendentes do Windows, usuario logado remotamente |
| v2.1 | 20/10/2026 | Interface com caixas, menu centralizado, busca remota completa, opcao `[0]` voltar ao menu |
| v2.0 | 19/10/2026 | Versao inicial modularizada |

---

## Autor

Desenvolvido por **Renato Moura** — TI | EXSA
[GitHub](https://github.com/Reinattos)