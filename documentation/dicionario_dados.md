<!-- -*- coding: utf-8; -*- -->

# Dicionário de Dados - Projeto 01 IBM HR

Este documento fornece a descrição detalhada das variáveis do modelo de dados expandido do dataset **IBM HR Analytics Employee Attrition & Performance**. O projeto foi reformulado em **Power BI** para analisar e identificar os principais fatores que influenciam a satisfação, a felicidade e o bem-estar dos colaboradores na organização, medindo em simultâneo o impacto de iniciativas internas de envolvimento (_engagement_) (Questionário da Mesa de _Ping-Pong_).

## 📊 Metadados do Projeto
* **Ferramenta Principal:** Microsoft Power BI
* **Idioma do Negócio:** Inglês (Nomes das colunas originais mantidos)
* **Idioma da Documentação:** Português (PT-PT)
* **Unidade de Distância:** Quilómetros (km) — *valores numéricos originais assumidos diretamente em km*
* **Arquitetura de Dados:** Multi-Fact Star Schema (Esquema em Estrela com Duas Tabelas de Factos)

---

## 📐 Arquitetura do Modelo (Multi-Fact Star Schema)

O modelo de dados segue os padrões de Business Intelligence para estruturas multi-facto. É composto por duas tabelas centrais de factos (`fact-attrition` e `fact-survey`) que partilham dimensões estruturais comuns, permitindo correlacionar de forma isolada os indicadores históricos de satisfação laboral com as respostas do novo inquérito interno.

### 1. Tabelas de Factos
* **`fact-attrition`**: Regista os eventos históricos do colaborador e os dados associados à sua saída ou permanência. Nesta modelagem normalizada, as variáveis de inquérito de clima ligam-se aos IDs de escala da dimensão de satisfação.
* **`fact-survey`**: Nova tabela de factos transacional que acolhe o inquérito específico de satisfação e feedback após a aquisição da mesa de _ping-pong_.

### 2. Tabelas de Dimensões
* **`dim-employee`**: Dimensão partilhada central. Agrupa todos os atributos demográficos, financeiros (salários) e as métricas de tempo de carreira profissional do colaborador. Filtra ambas as tabelas de factos através do `EmployeeNumber`.
* **`dim-education`**: Detalhes sobre a formação e nível académico (`Education_Id`).
* **`dim-department`**: Isola a estrutura de departamentos organizacionais da empresa (`Department_Id`).
* **`dim-job`**: Concentra os cargos específicos e os níveis hierárquicos de senioridade (`Job_Id`).
* **`dim-satisfaction`**: Atua como uma tabela de normalização e parametrização das escalas numéricas de avaliação (1 a 4). Contém a descrição textual do nível de satisfação (`Level`) e serve de ponte para as múltiplas colunas de notas nas duas tabelas de factos.

---

## 🗂️ Tabela de Atributos (Localização e Significado)

| Nome da Coluna (Original) | Tipo de Dados (Power BI) | Localização no Modelo | Descrição em Português (PT-PT) | Notas / Transformações |
| :--- | :--- | :--- | :--- | :--- |
| **Age** | Inteiro | `dim-employee` | Idade do colaborador (18 a 60 anos). | Métrica demográfica base. |
| **Attrition** | Texto | `fact-attrition` | Se o colaborador deixou a empresa (Yes/No). | Usado para mapear permanência vs. felicidade. |
| **BusinessTravel** | Texto | `dim-employee` | Frequência de viagens em trabalho. | Categoria comportamental. |
| **DailyRate** | Inteiro | `dim-employee` | Tarifa ou custo diário do colaborador. | Nível de custo do funcionário. |
| **Department** | Texto | `dim-department` | Departamento atual na empresa. | Estrutura organizacional. |
| **Department_Id** | Inteiro / Chave | `dim-department` / Factos | ID gerado para isolar o setor. | Chave de Relacionamento. |
| **DistanceFromHome** | Inteiro | `dim-employee` | Distância entre residência e o trabalho (em **km**). | Valores originais assumidos em km. |
| **Education** | Inteiro | *N/A* | *Coluna Ignorada / Normalizada* | Substituída pelo ID na dimensão. |
| **Education_Id** | Inteiro / Chave | `dim-education` / `fact-attrition` | ID de ligação para o nível de escolaridade. | Chave de Relacionamento. |
| **EducationField** | Texto | `dim-education` | Área de formação académica do colaborador. | Atributo categórico. |
| **EducationItem** | Texto | `dim-education` | Código ou item interno da classificação académica.| Atributo técnico. |
| **EducationLabel** | Texto | `dim-education` | Descrição textual do nível (Ex: Below College, College, Bachelor, Master, Doctor). | Atributo textual auxiliar. |
| **EmployeeCount** | Inteiro | *N/A* | *Coluna Ignorada*. | **Ignorado:** Valor fixo 1 removido. |
| **EmployeeNumber** | Inteiro / Chave | `dim-employee` / Factos | Identificador único do colaborador. | Chave Primária de ligação comum. |
| **EnvironmentSatisfaction** | Inteiro / Chave | `fact-attrition` / `fact-survey` | Grau de satisfação com o ambiente de trabalho. | Nota de clima (Lida via `dim-satisfaction`).|
| **Gender** | Texto | `dim-employee` | Género do colaborador (Female/Male). | Dado demográfico. |
| **HourlyRate** | Inteiro | `dim-employee` | Valor faturado/pago por hora ao colaborador. | Métrica financeira horária. |
| **JobInvolvement** | Inteiro / Chave | `fact-attrition` / `fact-survey` | Nível de envolvimento e dedicação ao trabalho. | Indicador comportamental. |
| **Job_Id** | Inteiro / Chave | `dim-job` / `fact-attrition` | ID gerado para isolar a função e o cargo. | Chave de Relacionamento. |
| **JobLevel** | Inteiro | `dim-job` | Nível hierárquico do cargo ocupado (1-5). | Senioridade na organização. |
| **JobRole** | Texto | `dim-job` | Função ou cargo desempenhado pelo colaborador. | Categoria funcional. |
| **JobSatisfaction** | Inteiro / Chave | `fact-attrition` / `fact-survey` | Nível de satisfação com o trabalho desempenhado.| Indicador de felicidade laboral. |
| **Level** | Texto | `dim-satisfaction` | Descrição textual da nota (Ex: Low, Medium, High, Very High). | Tradução da escala 1-4. |
| **MaritalStatus** | Texto | `dim-employee` | Estado civil do colaborador. | Dado demográfico. |
| **MonthlyIncome** | Inteiro | `dim-employee` | Rendimento ou salário mensal bruto. | Métrica de compensação. |
| **MonthlyRate** | Inteiro | `dim-employee` | Valor de custo mensal associado ao colaborador. | Indicador financeiro interno. |
| **NumCompaniesWorked** | Inteiro | `dim-employee` | Número de empresas onde o colaborador trabalhou antes. | Histórico profissional externo. |
| **Over18** | Texto | *N/A* | *Coluna Ignorada*. | **Ignorado:** Removido no Power Query. |
| **OverTime** | Texto | `dim-employee` | Indica se o colaborador faz horas extraordinárias. | Fator de impacto na qualidade de vida. |
| **PercentSalaryHike** | Inteiro | `dim-employee` | Percentagem de aumento salarial no último ano. | Indicador de valorização. |
| **PerformanceRating** | Inteiro | `dim-employee` | Avaliação de desempenho do último ano (1-4).| Métrica de produtividade. |
| **RelationshipSatisfaction**| Inteiro / Chave | `fact-attrition` / `fact-survey` | Nível de satisfação com as relações no trabalho. | Clima de equipa e integração. |
| **Satisfaction_Id** | Inteiro / Chave | `dim-satisfaction` | Código identificador da escala de notas (1-4). | Chave de Relacionamento. |
| **StandardHours** | Inteiro | *N/A* | *Coluna Ignorada*. | **Ignorado / Convertido num Parâmetro**. |
| **StockOptionLevel** | Inteiro | `dim-employee` | Nível de opções de ações atribuídas (0 a 3).| Benefício financeiro. |
| **Survey_Id** | Inteiro / Chave | `fact-survey` | Identificador único do inquérito de bem-estar. | Chave Primária (Inquérito). |
| **SurveyDate** | Data | `fact-attrition` / `fact-survey` | Data de realização do registo ou do inquérito. | Chave temporal de contexto. |
| **TotalWorkingYears** | Inteiro | `dim-employee` | Tempo total de carreira profissional em anos. | Experience de mercado. |
| **TrainingTimesLastYear** | Inteiro | `dim-employee` | Número de ações de formação no ano passado. | Investimento no colaborador. |
| **WorkLifeBalance** | Inteiro / Chave | `fact-attrition` / `fact-survey` | Equilíbrio entre a vida pessoal e profissional. | Indicador crítico de bem-estar. |
| **YearsAtCompany** | Inteiro | `dim-employee` | Total de anos de antiguidade na empresa atual. | Fidelização interna. |
| **YearsInCurrentRole** | Inteiro | `dim-employee` | Total de anos decorridos na função ou cargo atual. | Tempo de estagnação ou estabilidade. |
| **YearsSinceLastPromotion** | Inteiro | `dim-employee` | Anos decorridos desde a data da última promoção. | Ciclo de progressão de carreira. |
| **YearsWithCurrManager** | Inteiro | `dim-employee` | Total de anos sob a liderança do atual gestor. | Relação com a chefia direta. |

---

## 🔧 Notas de Modelagem em Power BI

### 1. Colunas Ignoradas no Modelo de Dados
Para otimizar o desempenho do motor VertiPaq do Power BI e eliminar cardinalidade desnecessária, as seguintes colunas foram removidas na etapa do **Power Query**:
* `EmployeeCount`: Removida por conter apenas o valor fixo `1` em todas as linhas.
* `Over18`: Removida por conter apenas a constante `Y`.
* `StandardHours`: Removida por apresentar sempre o valor fixo `80`.

### 2. Tratamento da Variable `StandardHours`
A coluna estática `StandardHours` foi completamente eliminada das tabelas e **convertida num Parâmetro de Negócio** dentro do Power BI. Isto permite que os cálculos de simulação baseados nas cargas de trabalho padrão sejam dinâmicos e ajustáveis sem sobrecarregar o modelo.

### 3. Unidades de Medida (`DistanceFromHome`)
Os valores numéricos originais da coluna `DistanceFromHome` foram mantidos intactos, alterando-se exclusivamente o rótulo e a interpretação da unidade de medida para **Quilómetros (km)** para cumprir os requisitos de localização do negócio de forma limpa.


---

## 📐 Arquitetura do Modelo (Multi-Fact Star Schema)

```mermaid
erDiagram
    dim-employee ||--o{ fact-attrition : "EmployeeNumber"
    dim-employee ||--o{ fact-survey : "EmployeeNumber"
    dim-education ||--o{ fact-attrition : "Education_Id"
    dim-department ||--o{ fact-attrition : "Department_Id"
    dim-job ||--o{ fact-attrition : "Job_Id"
    
    dim-satisfaction ||--o{ fact-attrition : "EnvironmentSatisfaction"
    dim-satisfaction ||--o{ fact-attrition : "JobInvolvement"
    dim-satisfaction ||--o{ fact-attrition : "JobSatisfaction"
    dim-satisfaction ||--o{ fact-attrition : "RelationshipSatisfaction"
    dim-satisfaction ||--o{ fact-attrition : "WorkLifeBalance"

    dim-satisfaction ||--o{ fact-survey : "EnvironmentSatisfaction"
    dim-satisfaction ||--o{ fact-survey : "JobInvolvement"
    dim-satisfaction ||--o{ fact-survey : "JobSatisfaction"
    dim-satisfaction ||--o{ fact-survey : "RelationshipSatisfaction"
    dim-satisfaction ||--o{ fact-survey : "WorkLifeBalance"

    dim-employee {
        int EmployeeNumber PK
        int Age
        string BusinessTravel
        int DailyRate
        int DistanceFromHome
        string Gender
        int HourlyRate
        string MaritalStatus
        int MonthlyIncome
        int MonthlyRate
        int NumCompaniesWorked
        string OverTime
        int PercentSalaryHike
        int PerformanceRating
        int StockOptionLevel
        int TotalWorkingYears
        int TrainingTimesLastYear
        int YearsAtCompany
        int YearsInCurrentRole
        int YearsSinceLastPromotion
        int YearsWithCurrManager
    }

    dim-education {
        int Education_Id PK
        string EducationField
        string EducationItem
        string EducationLabel
    }

    dim-department {
        int Department_Id PK
        string Department
    }

    dim-job {
        int Job_Id PK
        int JobLevel
        string JobRole
    }

    dim-satisfaction {
        int Satisfaction_Id PK
        string Level
    }

    fact-attrition {
        string Attrition
        int Department_Id FK
        int Education_Id FK
        int EmployeeNumber FK
        int Job_Id FK
        int EnvironmentSatisfaction FK
        int JobInvolvement FK
        int JobSatisfaction FK
        int RelationshipSatisfaction FK
        int WorkLifeBalance FK
        date SurveyDate
    }

    fact-survey {
        int EmployeeNumber FK
        int Survey_Id PK
        int EnvironmentSatisfaction FK
        int JobInvolvement FK
        int JobSatisfaction FK
        int RelationshipSatisfaction FK
        int WorkLifeBalance FK
        date SurveyDate
    }


---

```mermaid
erDiagram
    %% Relacionamentos de Dimensão para Factos
    dim-employee ||--o{ fact-attrition : "EmployeeNumber"
    dim-employee ||--o{ fact-survey : "EmployeeNumber"
    dim-education ||--o{ fact-attrition : "Education_Id"
    dim-department ||--o{ fact-attrition : "Department_Id"
    dim-job ||--o{ fact-attrition : "Job_Id"
    
    %% Relacionamentos de Satisfação para Factos
    dim-satisfaction ||--o{ fact-attrition : "EnvironmentSatisfaction / JobSatisfaction / ..."
    dim-satisfaction ||--o{ fact-survey : "EnvironmentSatisfaction / JobSatisfaction / ..."

    %% Definição das Entidades
    dim-employee {
        int EmployeeNumber PK
        int Age
        string BusinessTravel
        string Department
        int DistanceFromHome
        string EducationField
        string Gender
        int JobLevel
        string JobRole
        int MonthlyIncome
        string OverTime
        int TotalWorkingYears
    }
    dim-education { int Education_Id PK; string EducationLabel }
    dim-department { int Department_Id PK; string Department }
    dim-job { int Job_Id PK; string JobRole }
    dim-satisfaction { int Satisfaction_Id PK; string Level }
    fact-attrition {
        string Attrition
        int EmployeeNumber FK
        int EnvironmentSatisfaction FK
        int JobSatisfaction FK
        date SurveyDate
    }
    fact-survey {
        int Survey_Id PK
        int EmployeeNumber FK
        int EnvironmentSatisfaction FK
        int JobSatisfaction FK
        date SurveyDate
    }

