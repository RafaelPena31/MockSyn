# MockSyn Features

Este documento lista as features planejadas para o MockSyn, agrupadas por bloco funcional. A lista descreve o produto desejado, nao uma ordem de implementacao.

## 1. Macros

| Feature | O que e |
| --- | --- |
| `@Mocking` | Macro para gerar um mock completo a partir de um protocolo ou tipo suportado. |
| `@Stubbing` | Macro para gerar um stub simples, focado em devolver respostas pre-configuradas. |
| `@Spying` | Macro para gerar um spy que registra chamadas e, quando possivel, encaminha para uma implementacao real. |
| Configuracao de nome | Permite controlar o nome do tipo gerado, como `UserServiceMock`. |
| Configuracao strict/relaxed | Define se chamadas sem stub falham ou recebem valores default. |
| Configuracao de visibilidade | Permite gerar mocks `internal`, `public`, `package` etc. |

## 2. Tipos Suportados

| Feature | O que e |
| --- | --- |
| Protocolos | Suporte principal do framework. A macro le o protocolo e gera mock, stub ou spy conformando a ele. |
| Classes nao-final | Suporte opcional para classes sobrescreviveis, via subclass gerada. |
| Classes `NSObject` / `@objc dynamic` | Suporte opcional futuro para casos que passam pelo runtime Objective-C. |
| Final classes | Nao mockar diretamente; oferecer diagnostico e sugestao de protocolo ou wrapper. |
| Protocol inheritance | Suporte a protocolos que herdam de outros protocolos, comecando por heranca simples. |

## 3. Membros Suportados

| Feature | O que e |
| --- | --- |
| Metodos sync | Funcoes comuns, como `func load() -> User`. |
| Metodos `throws` | Funcoes que podem lancar erro. |
| Metodos `async` | Funcoes assincronas. |
| Metodos `async throws` | Funcoes assincronas que podem lancar erro. |
| Properties `get` | Propriedades somente leitura. |
| Properties `get set` | Propriedades leitura e escrita. |
| Metodos `Void` | Chamadas que nao retornam valor, mas precisam ser registradas e verificadas. |
| Static requirements | Requisitos estaticos de protocolo, quando geraveis por macro. |
| Subscripts | Suporte a `subscript`. |
| Initializers | Suporte onde fizer sentido para conformidade ou geracao de classe. |
| Overloads | Metodos com mesmo nome, mas assinaturas diferentes. |
| Operators | Possivel suporte avancado ou diagnostico claro quando nao suportado. |

## 4. Recursos Da Linguagem Swift

| Feature | O que e |
| --- | --- |
| Generics | Suporte a metodos ou protocolos genericos. |
| Associated types | Suporte a protocolos com `associatedtype`, quando possivel. |
| `where` clauses | Preservacao de restricoes genericas. |
| `Self` requirements | Suporte ou diagnostico para requisitos que usam `Self`. |
| `inout` parameters | Parametros que podem ser modificados pela funcao. |
| Variadic parameters | Parametros como `Int...`. |
| Closures | Parametros e retornos baseados em closures. |
| `@escaping` closures | Closures armazenaveis ou chamadas depois. |
| Actors/global actors | Preservacao de isolamento como `@MainActor`. |
| `Sendable` | Compatibilidade com regras de concorrencia do Swift. |

## 5. Stubbing

| Feature | O que e |
| --- | --- |
| `given` / `when` | API para declarar comportamento esperado. |
| `willReturn` | Define valor de retorno. |
| `willThrow` | Define erro lancado. |
| `willRun` | Define closure customizada para executar na chamada. |
| Retornos sequenciais | Retorna valores diferentes em chamadas sucessivas. |
| Stubs por argumento | Permite respostas diferentes conforme os argumentos. |
| Stubs de propriedade | Configura retorno de properties. |
| Stubs de setter | Configura ou observa atribuicoes em propriedades. |
| Relaxed defaults | Retornos automaticos para tipos conhecidos. |
| Default value registry | Registro customizavel de valores default. |

## 6. Verificacao

| Feature | O que e |
| --- | --- |
| `verify` | API para verificar se uma chamada aconteceu. |
| `once` | Verifica que ocorreu uma vez. |
| `never` | Verifica que nao ocorreu. |
| `times(n)` | Verifica quantidade exata. |
| `atLeast(n)` | Verifica minimo de chamadas. |
| `atMost(n)` | Verifica maximo de chamadas. |
| Verificacao por argumento | Confirma chamadas com argumentos especificos. |
| Ordem de chamadas | Verifica se uma chamada ocorreu antes ou depois de outra. |
| Ordem entre mocks | Verifica sequencia envolvendo multiplos mocks. |
| `confirmVerified` | Garante que todas as chamadas relevantes foram verificadas. |
| `checkUnnecessaryStubs` | Detecta stubs configurados mas nunca usados. |
| Timeout verify | Aguarda chamadas assincronas por uma janela de tempo. |

## 7. Matchers E Captors

| Feature | O que e |
| --- | --- |
| `.any` | Aceita qualquer valor. |
| `.value(x)` | Compara valor exato. |
| `.matching { }` | Usa predicado customizado. |
| `.nil` / `.notNil` | Matchers para opcionais. |
| Matchers de colecao | Matchers para arrays, sets e dictionaries. |
| Matchers compostos | Combina regras, como `not`, `all` e `anyOf`. |
| Argument captor | Captura argumentos recebidos para inspecao posterior. |
| Closure captor | Captura closures passadas como argumento. |

## 8. Modos De Test Double

| Feature | O que e |
| --- | --- |
| Strict mock | Falha quando uma chamada nao foi previamente configurada. |
| Relaxed mock | Retorna defaults automaticamente quando possivel. |
| Stub | Double simples para devolver respostas. |
| Spy | Double que registra chamadas e pode delegar para objeto real. |
| Partial spy | Spy que delega por padrao, mas permite sobrescrever alguns membros. |
| Fake helper | Possivel camada futura para objetos com comportamento simplificado, nao apenas stubs. |

## 9. Runtime Interno

| Feature | O que e |
| --- | --- |
| Call store | Armazena chamadas feitas ao mock. |
| Stub registry | Armazena regras de stubbing. |
| Invocation model | Representa uma chamada com nome, argumentos e ordem. |
| Argument boxing | Guarda argumentos heterogeneos de forma verificavel. |
| Thread safety | Protege estado interno em testes concorrentes. |
| Reset | Limpa chamadas e stubs. |
| Failure reporter | Canal unico para reportar falhas ao framework de testes. |

## 10. Integracao Com Testes

| Feature | O que e |
| --- | --- |
| XCTest adapter | Integra falhas com `XCTFail`. |
| Swift Testing adapter | Integra falhas com `Issue.record` / Swift Testing. |
| Custom reporter | Permite que o usuario defina como falhas sao reportadas. |
| File/line forwarding | Faz a falha apontar para a linha do teste. |
| Mensagens detalhadas | Explica chamada esperada, chamada recebida e stubs disponiveis. |

## 11. Diagnosticos

| Feature | O que e |
| --- | --- |
| Tipo invalido | Erro claro quando macro e usada em algo nao suportado. |
| Membro invalido | Erro claro para requisito nao geravel. |
| Final class diagnostic | Explica que uma final class Swift pura nao e mockavel diretamente. |
| Protocol inheritance diagnostic | Explica limites de heranca suportada. |
| Fix-its | Sugestoes automaticas quando possivel. |
| Matriz de suporte | Documentacao explicita do que e ou nao suportado. |

## 12. Ferramentas Opcionais

| Feature | O que e |
| --- | --- |
| Export de macro expansion | Documentacao e comandos para inspecionar o codigo expandido pelo compilador. |
| CLI de inspecao | Ferramenta futura para diagnostico local, sem participar do fluxo principal de geracao. |
| DocC | Documentacao oficial do pacote. |
| Guias de migracao | Orientacao para migrar de Mockable, Cuckoo, SwiftyMocky etc. |
| Benchmarks | Medicao de custo de build e runtime. |
