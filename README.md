# ELT Pipeline with dbt, Snowflake and Airflow

A dbt project that transforms Snowflake's TPC-H sample data into analytics-ready models, orchestrated with Airflow.

---

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Project Architecture](#project-architecture)
- [Loading the Data](#loading-the-data)
- [Staging Layer](#staging-layer)
- [Mart Models](#mart-models)
  - [Orders](#orders)
- [Macros](#macros)
- [Data Quality](#data-quality)
  - [Generic Tests](#generic-tests)
  - [Singular Tests](#singular-tests)
- [Orchestration](#orchestration)
- [Project Structure](#project-structure)

---

## Project Overview

This project builds an ELT pipeline for order data using **dbt** and **Snowflake**.

The raw data comes from Snowflake's own sample dataset, **TPC-H** (`snowflake_sample_data.tpch_sf1`), and represents orders and line items. The goal is to transform this raw data into a clean, tested fact table that can answer questions about order sales and discounts.

Dataset:
https://docs.snowflake.com/en/user-guide/sample-data-tpch

## Tech Stack

- dbt Core / dbt-snowflake
- Snowflake
- Apache Airflow (via Astro CLI)
- Astronomer Cosmos
- Git
- GitHub

## Project Architecture

Raw TPC-H data already lives in Snowflake as a shared sample database, so it's defined directly as a dbt **source** — no loading step is needed. dbt then builds staging models before creating the intermediate and mart models. The whole pipeline is scheduled and run by Airflow.

## Loading the Data

The `orders` and `lineitem` tables are provided by Snowflake in the `snowflake_sample_data.tpch_sf1` schema, so there's no separate loading step — they're referenced directly as dbt **sources** in `sources.yml`.

## Staging Layer

The staging layer renames and cleans up columns from the raw TPC-H tables:

- `stg__tpch_orders`: cleans up the `orders` source
- `stg__tpch_line_items`: cleans up the `lineitem` source, and generates a surrogate key for each line item using the `dbt_utils` package

## Mart Models

### Orders

**Grain:** One row per order.

The final `fct__orders` model combines order information with aggregated line-item data (total sales, total discount) to give a full picture of each order. It's built through two intermediate models:

- `int_order_items`: joins orders with their line items and calculates the discount amount per item
- `int_order_items_summary`: aggregates line items back up to the order level

## Macros

- `discounted_amount()`: calculates the discount amount for a line item from its price and discount percentage. Used in `int_order_items` instead of repeating the calculation inline.

## Data Quality

The project includes both generic and singular tests to ensure data quality.

### Generic Tests

The following dbt tests are used:

- `unique`
- `not_null`
- `accepted_values`
- `relationships`

These tests validate primary keys, mandatory fields, valid categorical values (`status_code` must be `P`, `O`, or `F`), and relationships between models.

### Singular Tests

Business rules are validated using singular SQL tests stored in the `/tests` directory:

- order dates must fall between 1990-01-01 and today
- discount amounts can never be negative

## Orchestration

The pipeline is orchestrated with **Apache Airflow**, run locally through the **Astro CLI**. Instead of writing the DAG by hand, it's generated automatically with **Astronomer Cosmos**, which turns the dbt project into an Airflow DAG.

The DAG connects to Snowflake through an Airflow connection (`snowflake_conn`) and is scheduled to run once a day.

---

# Project Structure

```text
.
├── dags/
│   ├── dbt/            # The dbt project
│   │   ├── analyses/
│   │   ├── macros/         # discounted_amount()
│   │   ├── models/
│   │   │   ├── staging/     # stg__tpch_orders, stg__tpch_line_items
│   │   │   └── marts/      # int_order_items, int_order_items_summary, fct__orders
│   │   ├── seeds/
│   │   ├── snapshots/
│   │   ├── tests/           # singular tests
│   │   └── dbt_project.yml
│   └── dbt_dag.py            # Airflow DAG, built with Cosmos
├── tests/dags/                # DAG validation tests
├── Dockerfile
├── packages.txt
├── requirements.txt
└── README.md
```
