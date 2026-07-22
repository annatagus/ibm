<!-- -*- coding: utf-8; -*- -->

# Projeto 01 IBM-HR 📊
Este repositório contém o projeto prático **Projeto 01 IBM-HR**, desenvolvido no âmbito do curso **AIDAPT-04** da **cegid Academy**. O objetivo principal do projeto é analisar dados de Recursos Humanos utilizando 'SQL', 'R' e 'Power BI' para gerar insights estratégicos.

O projeto será apresentado nos **dias 5 e 6 (primeira semana) de agosto de 2026** pelo **Grupo #2 _Power Squad_**.

---

## 👥 Elementos do Grupo
* Edgar Apolinário: 📧 edgarapolinario855 [at] gmail [dot] com :octocat: [@Edgar295](https://github.com/Edgar295)
* Nilton Ávido: 📧 capaia1986 [at] gmail [dot] com :octocat: [@NiltonAvido](https://github.com/NiltonAvido)
* Raquel Cunha: 📧 raquelmcunha [at] gmail [dot] com :octocat: [@annatagus](https://github.com/annatagus)
* Tiago Rodrigues: 📧 tiag0rkayh [at] gmail [dot] com :octocat: [@Tiago-Alex](https://github.com/Tiago-Alex)

## 👨‍🏫 Professor Orientador
* João Lauro de Marco: 💼 https://pt.linkedin.com/in/joao-lauro-de-marco/pt

---

## 📁 Organização do Repositório

Para manter o projeto limpo e colaborativo no Git, a estrutura de pastas foi organizada da seguinte forma:

* **`/componente SQL`**: Armazena os scripts SQL (`.sql`) desenvolvidos no SQL Server para a extração, transformação e modelagem prévia dos dados de RH.
* **`/dashboards`**: Contém os ficheiros de desenvolvimento e relatórios finais do Power BI (`.pbix` ou `.pbip`).
* **`/documentation`**: Centraliza os ficheiros de suporte do projeto, incluindo o relatório escrito em Word/PDF, a apresentação em PowerPoint e o levantamento de requisitos.
* **`/img`**: Armazena os recursos visuais do projeto, como logótipos, ícones e imagens de fundo (*backgrounds*) usadas no design das páginas do relatório.
* **`/source-data`**: Guarda os ficheiros originais em Excel que servem como fonte de dados (dados brutos/crus) para o Power BI.

---

## 🚀 Como Executar o Projeto

1. **Clonar o Repositório:**
   ```bash
   git clone https://github.com/annatagus/ibm.git
   ```
2. **Fontes de Dados:** As bases de dados em Excel encontram-se na pasta `/source-data`.
3. **Abrir o Relatório:** Garanta que tem o *Power BI Desktop* instalado e abra o ficheiro guardado na pasta `/dashboards`.
   * *Nota:* Caso as ligações de dados falhem ao abrir noutro computador, verifique a configuração dos caminhos das fontes no Power Query.

---

## 🛠️ Tecnologias Utilizadas
* **Microsoft Power BI** - Tratamento de dados (Power Query), modelagem e criação de dashboards.
* **Microsoft SQL Server** - Armazenamento e consulta à base de dados relacional.
* **R (Google Colab)** - Análise estatística e manipulação avançada de dados em ambiente cloud.
* **Microsoft Excel** - Armazenamento e consulta dos ficheiros de dados originais.
* **Microsoft Word / PowerPoint / PDF** - Criação de relatórios escritos e suporte para a apresentação.
* **Git & GitHub** - Controlo de versão e ambiente colaborativo para o grupo.

---

## 📐 Modelo de Dados (Multi-Fact Star Schema)

Para garantir o máximo desempenho e eficiência no Power BI, o modelo foi estruturado seguindo um esquema em estrela com múltiplas tabelas de factos (*Multi-Fact Star Schema*). Esta arquitetura é composta por duas tabelas centrais de factos (`fact-attrition` e `fact-survey`) que partilham dimensões comuns, permitindo correlacionar de forma isolada os indicadores históricos de satisfação laboral com os resultados do novo inquérito interno (mesa de _ping-pong_).

* 🔍 [Visualizar Imagem do Modelo Multi-Fact Star Schema (PNG)](img/modelo_multi_fact_star_schema.png)
* 📖 [Consultar Dicionário de Dados Detalhado](documentation/dicionario_dados.md) (Tipos de dados, transformações e mapeamento de chaves)
