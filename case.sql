
CREATE TABLE tblivro(
idLivro INT PRIMARY KEY IDENTITY(1,1),
titulo VARCHAR(150) NOT NULL,
autor VARCHAR(150) NOT NULL,
isbn VARCHAR(20) UNIQUE NOT NULL,
anoPublicacao INT,
disponivel BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE tbusuario(
idUsuario INT PRIMARY KEY IDENTITY(1,1),
nome VARCHAR(250) NOT NULL,
email VARCHAR(250) UNIQUE NOT NULL
);
GO

CREATE TABLE tbemprestimo(
idEmprestimo INT PRIMARY KEY IDENTITY(1,1),
livro_id INT NOT NULL,
usuario_id INT NOT NULL,
dataEmprestimo DATETIME2 NOT NULL DEFAULT GETDATE(),
dataDevolucao DATETIME2 NULL,
status VARCHAR(20) NOT NULL DEFAULT 'Ativo',

CONSTRAINT livro_fk FOREIGN KEY (livro_id) REFERENCES tblivro(idLivro) ON DELETE NO ACTION,
CONSTRAINT usuario_fk FOREIGN KEY (usuario_id) REFERENCES tbusuario (idUsuario) ON DELETE NO ACTION
);
GO


-- Adicionar livro
CREATE OR ALTER PROCEDURE sp_inserirLivro
	@titulo VARCHAR(150),
	@autor VARCHAR(150),
	@isbn VARCHAR(20),
	@ano INT
	

AS
	BEGIN
	INSERT INTO tblivro (titulo, autor, isbn, anoPublicacao)
	VALUES (@titulo, @autor, @isbn, @ano);
	END
GO

-- Visualizar livro
CREATE OR ALTER PROCEDURE sp_mostrarLivro
	@idLivro INT = NULL
AS
	BEGIN
	SELECT *
	FROM tblivro
		WHERE idLivro = @idLivro OR @idLivro IS NULL;
	END
GO

-- Atualizar livro
CREATE OR ALTER PROCEDURE sp_atualizarLivro
	@idLivro INT,
	@titulo VARCHAR(150),
	@autor VARCHAR(150),
	@isbn VARCHAR(20),
	@ano INT,
	@disponivel BIT
AS
	BEGIN
	UPDATE tblivro
		SET titulo = @titulo,
			autor = @autor,
			isbn = @isbn,
			anoPublicacao = @ano,
			disponivel = @disponivel
		WHERE idLivro = @idLivro;
	END
GO

-- Excluir livro (caso não exista empréstimo)
CREATE OR ALTER PROCEDURE sp_deletarLivro
	@idLivro INT
AS
	BEGIN
	IF EXISTS (SELECT 1 FROM tbemprestimo WHERE livro_id = @idLivro AND dataDevolucao IS NULL)
		BEGIN
		RAISERROR('Livro já em empréstimo, não pode ser deletado.',16,1);
		RETURN;
		END
	
	DELETE FROM tblivro WHERE idLivro = @idLivro;

		-- Tratar erros (básico) - Verifica se alguma linha foi afetada
		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR('Livro não encontrado.', 16, 2);
			RETURN;
		END
	END
GO


-- Adicionar Usuário
CREATE OR ALTER PROCEDURE sp_inserirUsuario
	@nome VARCHAR(250),
	@email VARCHAR(250)
AS
	BEGIN
	INSERT INTO tbusuario (nome, email)
	VALUES (@nome, @email);
	END
GO

-- Visualizar Usuário
CREATE OR ALTER PROCEDURE sp_mostrarUsuario
	@idUser INT = NULL
AS
	BEGIN
	SELECT *
	FROM tbusuario
	WHERE idUsuario = @idUser OR @idUser IS NULL;
	END
GO

-- Atualizar Usuário
CREATE OR ALTER PROCEDURE sp_atualizarUsuario
	@idUser INT,
	@nome VARCHAR(250),
	@email VARCHAR(250)
AS
	BEGIN
	UPDATE tbusuario
		SET nome = @nome,
			email = @email
		WHERE idUsuario = @idUser;
	END
GO

-- Excluir Usuário (Impede exclusao se tiver emprestimos)
CREATE OR ALTER PROCEDURE sp_deletarUsuario
	@idUser INT
AS
	BEGIN
	DELETE FROM tbusuario WHERE idUsuario = @idUser;

	IF @@ROWCOUNT = 0
	BEGIN
		RAISERROR('Usuário não encontrado ou não pode ser deletado (empréstimos pendentes).', 16, 1);
		RETURN;
	END
	END
GO


-- Adicionar empréstimo (Livro deve estar disponível)
CREATE OR ALTER PROCEDURE sp_inserirEmprestimo
	@livro_id INT,
	@usuario_id INT
AS
	BEGIN
	IF EXISTS (SELECT 1 FROM tblivro WHERE idLivro = @livro_id AND disponivel = 0)

		BEGIN
		RAISERROR('Livro indisponível.', 16, 1);
		RETURN;
		END

	INSERT INTO tbemprestimo (livro_id, usuario_id)
	VALUES (@livro_id, @usuario_id);

	UPDATE tblivro
		SET disponivel = 0
		WHERE idLivro = @livro_id;
	END
GO

-- Visualizar empréstimo
CREATE OR ALTER PROCEDURE sp_mostrarEmprestimo
	@idEmp INT = NULL
AS
	BEGIN
		SELECT e.idEmprestimo, l.titulo AS livro, u.nome AS usuario, e.dataEmprestimo, e.dataDevolucao, e.status
		FROM tbemprestimo e
			INNER JOIN tblivro l ON e.livro_id = l.idLivro
			INNER JOIN tbusuario u ON e.usuario_id = u.idUsuario
			WHERE e.idEmprestimo = @idEmp OR @idEmp IS NULL;
	END
GO

-- Atualizar empréstimo (Devolve livro caso status = 'Devolvido')
CREATE OR ALTER PROCEDURE sp_atualizarEmprestimo
	@idEmp INT,
	@dataDevo DATETIME2,
	@status VARCHAR(20)
AS
	BEGIN
	UPDATE tbemprestimo
		SET dataDevolucao = @dataDevo,
			status = @status
		WHERE idEmprestimo = @idEmp;

	IF @status = 'Devolvido'
		BEGIN
			DECLARE @livro INT;
			SELECT @livro = livro_id
			FROM tbemprestimo
				WHERE idEmprestimo = @idEmp;

			-- Reseta/Atualiza status do livro
			UPDATE tblivro
				SET disponivel = 1
				WHERE idLivro = @livro;
		END
	END
GO

-- Deletar empréstimo
CREATE OR ALTER PROCEDURE sp_deletarEmprestimo
	@idEmp INT
AS
	BEGIN
	DELETE FROM tbemprestimo
		WHERE idEmprestimo = @idEmp;

		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR('Empréstimo não encontrado.', 16, 1);
			RETURN;
		END
	END
GO
