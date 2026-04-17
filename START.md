# Como Iniciar o Projeto com Docker (Test Environment)

Este guia descreve os passos necessários para buildar e rodar o projeto utilizando o `docker-compose.test.yaml`.

## Passos Realizados

### 1. Build das Imagens

O primeiro passo é construir as imagens Docker necessárias. Como o ambiente exige permissões de superusuário, utilizamos o `sudo`.

```bash
sudo docker compose -f docker-compose.test.yaml build
```

### 2. Preparação do Banco de Dados

Após o build, é necessário criar e rodar as migrações do banco de dados (Postgres) dentro do container do Rails.

```bash
sudo docker compose -f docker-compose.test.yaml run --rm rails bundle exec rake db:prepare
```

### 3. Inicialização dos Serviços

Com o banco preparado, iniciamos todos os serviços (Rails, Sidekiq, Postgres, Redis) em modo _detached_ (-d).

```bash
sudo docker compose -f docker-compose.test.yaml up -d
```

## Comandos Úteis

### Ver Logs

Para acompanhar o que está acontecendo no servidor Rails:

```bash
sudo docker compose -f docker-compose.test.yaml logs -f rails
```

### Parar os Serviços

Para parar e remover os containers:

```bash
sudo docker compose -f docker-compose.test.yaml down
```

### Acessar a Aplicação

Após iniciar os serviços, a aplicação estará disponível em:
[http://localhost:3000](http://localhost:3000)
