Com certeza\! Incluir o bloco de teste diretamente no README, dentro de uma seção de código, é a melhor forma de garantir que o avaliador veja a prova de conceito imediatamente.

Aqui está o **README.md** completo, com o bloco de teste integrado:

-----

## 🚀 Desafio de Estágio: Sistema de Gestão de Biblioteca (T-SQL)

Este documento apresenta a solução completa para o desafio de modelagem e implementação de um sistema básico de biblioteca, utilizando **Transact-SQL (T-SQL)** para o ambiente SQL Server.

O objetivo foi construir um único script `.sql` que define a estrutura de dados e centraliza toda a lógica de negócio em Stored Procedures.

-----

### 1\. Destaques da Solução

Minha entrega cumpre e **supera** os requisitos mínimos, focando em robustez e boas práticas:

| Funcionalidade | Implementação | Benefício |
| :--- | :--- | :--- |
| **Modelagem** | 3 Tabelas (`Livro`, `Usuário`, `Empréstimo`) com PKs e FKs implementadas. | Estrutura escalável e clara para o negócio. |
| **Integridade de Dados** | **`ON DELETE NO ACTION`** em todas as FKs. | Impede que Livros ou Usuários sejam excluídos se houverem empréstimos ativos, protegendo o histórico. |
| **Lógica de Empréstimo** | Controle de status (`disponivel` e `status`). | O sistema não permite emprestar um livro que já está na mão de outro usuário. |
| **Qualidade do Código** | **CRUD Completo** para todas as entidades e uso de **`CREATE OR ALTER PROCEDURE`**. | Código organizado, reutilizável e fácil de manter/atualizar. |
| **Tratamento de Erro** | Mensagens de erro personalizadas (**`RAISERROR`**). | Retorna feedback claro ao usuário (ex: "Livro já emprestado"), em vez de erros genéricos. |

-----

### 2\. Entidades e Relacionamentos

A solução é construída em torno de três entidades principais:

| Entidade | Chaves Principais | Detalhe Importante |
| :--- | :--- | :--- |
| **`tblivro`** | `idLivro` (PK) | Coluna **`disponivel`** (BIT) para rastreamento de status. |
| **`tbusuario`** | `idUsuario` (PK) | Garante que cada usuário tenha um **e-mail único** (`UNIQUE`). |
| **`tbemprestimo`** | `idEmprestimo` (PK) | Liga um Livro a um Usuário, contendo o `status` ('Ativo', 'Devolvido'). |

-----

### 3\. Procedimentos: A Lógica Centralizada

Todas as operações são encapsuladas em **Stored Procedures**, seguindo a nomenclatura `sp_AçãoEntidade` (ex: `sp_inserirLivro`).

  * **Lógica de Empréstimo/Devolução:**
      * `sp_inserirEmprestimo` verifica a disponibilidade e marca o livro como **indisponível**.
      * `sp_atualizarEmprestimo` reverte a disponibilidade do livro se o status for alterado para 'Devolvido'.
  * **Deleção Segura:**
      * `sp_deletarLivro` contém uma validação extra para bloquear a exclusão se houver um empréstimo ativo, reforçando a integridade.

-----

### 4\. Bloco de Teste de Funcionalidade

Para demonstrar a eficácia e a lógica de negócio implementada, o script a seguir (que deve ser incluído no arquivo `.sql` após as Procedures) prova o fluxo de trabalho do sistema:

```sql

-- 1. Insere um Usuario e um Livro
EXEC sp_inserirUsuario @nome = 'Jack Sparrow', @email = 'jack@teste.com';
EXEC sp_inserirLivro @titulo = 'Piratas do Caribe', @autor = 'Rob Kidd', @isbn = '9991234567890', @ano = 2025;
GO

PRINT '--- SELECT: Visualizando Livro e Usuario Inseridos ---';
EXEC sp_mostrarLivro;
EXEC sp_mostrarUsuario;
GO

-- 2. Tenta deletar o livro (SUCESSO)
PRINT '--- DELETE: Tentando deletar livro (SUCESSO) ---';
EXEC sp_deletarLivro @idLivro = 1; -- Assume idLivro = 1
GO

-- 3. Insere o livro novamente para o teste de emprestimo
EXEC sp_inserirLivro @titulo = 'Modelagem Profissional', @autor = 'T-SQL Expert', @isbn = '9991234567890', @ano = 2025;
GO

-- 4. Cria um Empréstimo (Livro fica INDISPONIVEL)
PRINT '--- INSERT: Criando Emprestimo (Livro 2 fica indisponivel) ---';
EXEC sp_inserirEmprestimo @livro_id = 2, @usuario_id = 1;
GO

-- 5. Tenta deletar o livro emprestado (DEVE FALHAR por causa do emprestimo ativo)
PRINT '--- DELETE: Tentando deletar livro emprestado (DEVE FALHAR) ---';
EXEC sp_deletarLivro @idLivro = 2;
GO

-- 6. Atualiza o Empréstimo (Devolve o livro - Livro volta a ficar DISPONIVEL)
PRINT '--- UPDATE: Devolvendo Emprestimo (Livro 2 volta a ficar disponivel) ---';
EXEC sp_atualizarEmprestimo @idEmp = 1, @dataDevo = '2025-10-01', @status = 'Devolvido';
GO

-- 7. Tenta deletar o livro novamente (DEVE TER SUCESSO agora)
PRINT '--- DELETE: Tentando deletar livro devolvido (SUCESSO) ---';
EXEC sp_deletarLivro @idLivro = 2;
GO
```
