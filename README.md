# Canaril — Sistema de gestão de canários

Aplicativo de página única (`index.html`) para controlar um criatório de canários e outras espécies: cadastro de aves, casais, posturas, ovos, choco, nascimentos, saúde/manejo, clubes e anilhas, campeonatos e relatórios. Em português do Brasil, pensado para o celular.

- **Link de acesso (claude.ai)**: https://claude.ai/artifact/CBsPV9bd1gbg2BwFXoFs6o — aberto por ali, os dados ficam salvos na nuvem e aparecem iguais no celular e no computador.
- **Compartilhar para teste**: cada pessoa que abre o link tem a sua própria área de dados (`data/users/<id>/` no banco do artifact), invisível para as outras. Para salvar na nuvem, o convidado precisa ser adicionado como **Editor** pelo menu Compartilhar do claude.ai, com o acesso por link público desligado; sem isso, os dados dele ficam só no navegador e o app avisa.
- **Sem instalação e sem servidor**: abra o arquivo no navegador (ou publique junto com o site). Funciona offline.
- **Aberto como arquivo ou pelo site**, os dados ficam no próprio aparelho (`localStorage` do navegador). Use **☰ → Salvar backup** com frequência: o arquivo `.json` serve de cópia de segurança e para levar os dados a outro aparelho (**Restaurar backup**).
- **Exportação**: Excel (`.xlsx` com todas as tabelas + aba de indicadores) e CSV por tabela (separador `;`, abre direto no Excel em pt-BR).
- No celular, use “Adicionar à tela inicial” do navegador para abrir como app.

---

## 1. Estrutura dos dados

Todas as tabelas ficam num único objeto JSON. Datas no formato `AAAA-MM-DD`. As relações entre aves usam a **anilha** (única, sem repetição; espaços e maiúsculas/minúsculas são ignorados na comparação). As demais relações usam o `id` interno.

```
Aves ──< Casais (macho, femea) ──< Posturas ──< Ovos
 ▲                                   │  └──1 Chocos ──< AcompanhamentoChoco
 └── filhote (pai, mae, posturaId) ──┘
Aves ──< Manejos            Lembretes ──(ao concluir)──> Manejos
```

### Aves (`aves`)
| Campo | Tipo | Observação |
|---|---|---|
| id | texto | interno |
| anilha | texto | **único**; obrigatório. Filhotes sem anilha recebem `S/A-n` provisório |
| origem | `comprado` \| `nascido` | |
| vendedor | texto | se comprado — vendedor/criadouro |
| dataAquisicao | data | se comprado |
| valorPago | número (R$) | se comprado |
| anilhaOriginal | texto | se comprado |
| dataNascimento | data | se nascido |
| pai, mae | anilha | se nascido → Aves |
| posturaId | id | se nascido no plantel → Posturas |
| sexo | `M` \| `F` \| `I` | I = indeterminado até a maturidade |
| cor, mutacao, linhagem | texto | com sugestões dos valores já usados |
| situacao | `ativo` \| `reprodutor` \| `reservado` \| `vendido` \| `doado` \| `morto` \| `descartado` | os três primeiros contam como “ativas” |
| local | texto | viveiro ou gaiola |
| dataSaida, motivoSaida | data, texto | venda, doação, morte ou descarte/aposentadoria |
| valorVenda | número (R$) | se vendido |
| obs | texto livre | |

### Casais (`casais`)
| Campo | Tipo | Observação |
|---|---|---|
| id | texto | |
| macho, femea | anilha | → Aves (um macho pode ter mais de uma fêmea) |
| viveiro | texto | |
| dataFormacao, dataSeparacao | data | sem separação = casal ativo |
| obs | texto | |

O **histórico de temporadas por casal** é calculado a partir das posturas (tela do casal).

### Posturas — ciclos de reprodução (`posturas`)
| Campo | Tipo | Observação |
|---|---|---|
| id | texto | |
| casalId | id | → Casais |
| dataInicio | data | 1º ovo |
| status | `ativa` \| `encerrada` | |
| obs | texto | |
| *nº de ovos* | calculado | contagem de Ovos |
| *eclosão prevista* | calculado | último ovo + 13 dias (configurável); se o choco começou depois do último ovo, conta a partir do choco |
| *temporada* | calculado | pela data de início; a temporada começa em julho (configurável) → ex.: `2026/27` |

### Ovos (`ovos`)
| Campo | Tipo | Observação |
|---|---|---|
| id | texto | |
| posturaId | id | → Posturas |
| ordem | número | ordem na postura |
| data | data | data da postura do ovo |
| status | `pendente` \| `fertil` \| `infertil` \| `eclodido` \| `quebrado` \| `perdido` | pendente = ainda não verificado |
| obs | texto | ex.: ovo claro, casca fina |

### Chocos (`chocos`) e acompanhamento (`chocoEventos`)
| Campo | Tipo | Observação |
|---|---|---|
| id, posturaId | texto, id | 1 choco por postura |
| femea | anilha | fêmea chocando |
| dataInicio | data | início do choco |
| status | `chocando` \| `concluido` \| `abandonado` | |
| obs | texto | |
| **chocoEventos**: chocoId, data, alimentacaoExtra (sim/não), sinal (`normal`, `fora` do ninho, `abandono`, `ovofora`, `problema`), obs | | sinal de abandono/problema gera alerta |

### Filhotes
Filhotes são **Aves com origem `nascido`** (mesma tabela), ligados à postura e aos pais. Status do filhote = mantido / vendido / doado / morto (derivado da situação). Mortes na criação ficam em `dataSaida` + `motivoSaida`.

### Manejos (`manejos`)
| Campo | Tipo | Observação |
|---|---|---|
| id | texto | |
| anilha | anilha | vazio = registro geral (ex.: limpeza) |
| local | texto | |
| data | data | |
| tipo | `pesagem` \| `vermifugacao` \| `tratamento` \| `vitamina` \| `anilhamento` \| `veterinario` \| `limpeza` \| `outro` | |
| peso | número (g) | pesagem |
| produto, dose | texto | vermifugação/tratamento/vitamina |
| obs | texto | observações veterinárias |

Aplicar um manejo a um viveiro ou a “todas as ativas” cria um registro por ave, para aparecer no histórico de cada uma.

### Lembretes (`lembretes`)
`titulo`, `tipo` (de manejo), `intervaloDias`, `proxima` (data), `alvoTipo` (`todas` \| `local` \| `ave` \| `geral`), `alvo`, `ativo`, `obs`. “✓ Feito hoje” grava o manejo e reagenda.

### Espécies (`especies`)
`nome`, `diasEclosao` (incubação: último ovo → eclosão), `diaAnilhamento` (a partir de qual dia de vida anilhar), `maturidadeDias` (idade para definir o sexo), `diametroAnilha`, `obs`. Vêm prontas: canário (13), periquito-australiano (18), calopsita (19), agapornis (23), diamante-mandarim (13) e diamante-de-gould (15), todas editáveis. Cada ave tem `especieId`; a espécie de uma postura é a da fêmea do casal.

### Clubes (`clubes`)
`nome`, `sigla`, `federacao`, `numeroCriador`, `anuidadeValidade` (data), `contato`, `obs`.

### Lotes de anilhas (`lotesAnilhas`)
`clubeId` → Clubes, `especieId` (vazio = qualquer), `ano`, `prefixo`, `inicio`, `fim`, `digitos`, `diametro`, `obs`. A anilha é `prefixo + número` com zeros à esquerda (ex.: `HG 26` + 3 dígitos → `HG 26 001`). Anilhas usadas e a próxima livre são calculadas comparando com as aves cadastradas; o clube de uma ave vem do lote da anilha (ou de `aves.clubeId`, quando informado).

### Campeonatos (`eventos`) e inscrições (`inscricoes`)
- **eventos**: `nome`, `tipo` (`exposicao` \| `canto` \| `outro`), `clubeId` ou `organizador`, `local`, `dataInicio`, `dataFim`, `prazoInscricao`, `taxa`, `obs`, `checklist` (lista de itens de preparação com `t` e `ok`).
- **inscricoes**: `eventoId` → Eventos, `modalidade` (`individual` \| `equipe`), `anilhas` (lista de anilhas → Aves), `classe`, `juiz`, `pontos`, `colocacao`, `premio`, `obs` (notas da ficha).

### Perfil do criador (`perfil`)
Objeto único: `nome`, `criatorio`, `codigo` (sigla usada nas anilhas), `cidade`, `uf`, `telefone`, `email`, `sispass` (registro SISPASS/IBAMA, para espécies nativas), `desde` (ano), `obs`. Os clubes em que o criador é sócio são a tabela Clubes. O perfil é mantido ao carregar dados de exemplo e ao “Apagar tudo”.

### Configurações (`cfg`)
`inicioTemporada` (mês, padrão 7 = julho; 1 = ano civil), `especiePadrao`, `ultimoBackup`. (`diasEclosao` é legado: os dias de incubação agora ficam em cada espécie.)

---

## 2. Indicadores (aba Relatórios)

| Indicador | Fórmula |
|---|---|
| Natalidade | filhotes ÷ casais que fizeram postura |
| Fertilidade | ovos férteis (inclui eclodidos) ÷ total de ovos |
| Eclosão | ovos eclodidos ÷ ovos férteis |
| Mortalidade de filhotes | filhotes mortos ÷ filhotes nascidos |

Mostrados por temporada (ou geral), **por casal**, **por linhagem**, **resumo mensal** (ovos, nascimentos, mortes, vendas e receita, compras e gasto, manejos) e **resumo anual** por temporada.

## 3. Alertas automáticos (tela Início)

- Eclosão em até 2 dias, hoje ou **atrasada**
- Ovoscopia: ovos “não verificados” com 6+ dias
- Filhotes sem anilha a partir do 5º dia de vida
- Choco com sinal de abandono/problema
- Lembretes de manejo vencidos, de hoje ou dos próximos 2 dias
- Aves com 5+ meses e sexo indeterminado
- Backup com mais de 30 dias
- Prazo de inscrição de campeonato em até 7 dias e campeonato em até 3 dias (com itens de preparação pendentes)
- Anuidade de clube vencida ou vencendo em até 30 dias
- Lote de anilhas do ano com 5 ou menos anilhas livres

## 4. Dados de exemplo

Na primeira abertura toque em **Carregar dados de exemplo** (ou ☰ → Ajuda e testes). São 39 aves, 6 casais, 2 temporadas, posturas em várias fases (atrasada, eclodindo hoje, aguardando ovoscopia, filhotes para anilhar), manejos e lembretes. As datas são relativas ao dia de hoje, então os alertas sempre aparecem. Para começar de verdade: ☰ → **Apagar tudo**.

---

## 5. Guia rápido

### Cadastrar uma nova ave
1. **Início → 🐤 Nova ave** (ou aba Aves → ＋ Nova ave).
2. Digite a **anilha** (o sistema recusa anilha repetida).
3. Escolha a **origem**: *Comprado* → vendedor, data, valor, anilha original; *Nascido no plantel* → data de nascimento, pai e mãe.
4. Sexo, cor, mutação, linhagem, situação e viveiro/gaiola → **Salvar**.

### Registrar uma postura
1. O casal precisa existir: **Reprodução → Casais → ＋ Novo casal** (macho, fêmea, viveiro, data).
2. Primeiro ovo: **Início → 🥚 Ovo** → toque no casal em “iniciar postura”.
3. Cada novo ovo: **🥚 Ovo** → toque no casal (**1 toque por ovo**, com a data de hoje). A eclosão prevista é calculada sozinha.
4. Quando a fêmea começar a chocar: **🪺 Choco** na postura; use **＋ Acompanhamento** para alimentação extra e comportamento.
5. No 6º–7º dia: **🔦 Ovoscopia** e marque Fértil / Claro em cada ovo. Tocar num ovo também permite mudar o status e anotar observações.

### Registrar um nascimento
1. **Início → 🐣 Nascimento** → toque no casal.
2. Informe quantos nasceram (e as anilhas, se já tiver). Os ovos viram “eclodido” e os filhotes são criados com pai, mãe, linhagem e local do casal.
3. Sem anilha? Deixe em branco: entram como `S/A-1`, `S/A-2`… e a partir do 5º dia o Início avisa **💍 Anilhar** (a troca de anilha atualiza todas as referências).
4. Se um filhote morrer: abra a ave → **† Morte** → data e motivo.

### Clubes, anilhas e campeonatos
1. ☰ → **🐦 Espécies**: confira os dias de incubação, de anilhamento e a idade de sexagem das espécies que você cria.
2. ☰ → **🏛️ Clubes e anilhas**: cadastre cada clube e os lotes de anilhas recebidos. Ao anilhar, o app já preenche as próximas anilhas livres.
3. Aba **🏆 Torneios** → ＋ Novo campeonato. Abra o evento para marcar o checklist de preparação e **＋ Inscrever ave** (individual ou equipe).
4. Depois do julgamento, toque na inscrição e lance pontos, colocação e prêmio. Em **Resultados** aparecem os rankings por linhagem e por casal.
