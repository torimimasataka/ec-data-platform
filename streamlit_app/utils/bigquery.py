import os
import streamlit as st
import pandas as pd
from google.cloud import bigquery

PROJECT  = os.environ.get("DBT_BQ_PROJECT", "ec-data-platform-2026")
DS_APP   = "05_application"

LOCATION = "asia-northeast1"


@st.cache_resource
def get_client() -> bigquery.Client:
    return bigquery.Client(project=PROJECT)


@st.cache_data(ttl=3600)
def run_query(sql: str) -> pd.DataFrame:
    client = get_client()
    return client.query(sql, location=LOCATION).to_dataframe()


def load_summary_kpi() -> pd.DataFrame:
    return run_query(f"""
        SELECT *
        FROM `{PROJECT}.{DS_APP}.app_summary_kpi`
        ORDER BY year_month
    """)


def load_category_monthly() -> pd.DataFrame:
    """Raw monthly revenue/orders/customers per category (for client-side filtering)."""
    return run_query(f"""
        SELECT
            product_category_name_english,
            order_month,
            sum_price_month,
            cnt_orders_month,
            cnt_unique_customers_month
        FROM `{PROJECT}.{DS_APP}.app_category_performance`
        ORDER BY order_month
    """)


def load_geo_monthly() -> pd.DataFrame:
    """Raw monthly orders/revenue/customers per state (for client-side filtering)."""
    return run_query(f"""
        SELECT
            customer_state,
            state_name_en,
            order_month,
            cnt_orders_month,
            sum_price_month,
            cnt_unique_customers_month
        FROM `{PROJECT}.{DS_APP}.app_geo_summary`
        ORDER BY order_month
    """)


def load_category_customer_kpi() -> pd.DataFrame:
    """Monthly repeat-rate KPI per category (for KPI cards when category filter applied)."""
    return run_query(f"""
        SELECT
            product_category_name_english,
            order_month,
            cnt_unique_customers_month,
            cnt_repeat_customers_month,
            repeat_customer_rate_month
        FROM `{PROJECT}.{DS_APP}.app_category_customer_kpi`
        ORDER BY order_month
    """)


def load_state_customer_kpi() -> pd.DataFrame:
    """Monthly repeat-rate KPI per state (for KPI cards when state filter applied).
    Joins with app_geo_summary to include state_name_en for slicer matching."""
    return run_query(f"""
        SELECT
            k.customer_state,
            g.state_name_en,
            k.order_month,
            k.cnt_unique_customers_month,
            k.cnt_repeat_customers_month,
            k.repeat_customer_rate_month
        FROM `{PROJECT}.{DS_APP}.app_state_customer_kpi` k
        LEFT JOIN (
            SELECT DISTINCT customer_state, state_name_en
            FROM `{PROJECT}.{DS_APP}.app_geo_summary`
        ) g USING (customer_state)
        ORDER BY k.order_month
    """)


def load_cross_monthly() -> pd.DataFrame:
    """Category × State × Month cross table for universal slicer filtering.
    state_name_en is not fetched here — it is mapped in Python using the
    canonical geo data (app_geo_summary) after loading."""
    return run_query(f"""
        SELECT
            product_category_name_english,
            customer_state,
            state_name_en,
            DATE(order_month) AS order_month,
            sum_price_month,
            cnt_orders_month
        FROM `{PROJECT}.{DS_APP}.app_cross_monthly`
        ORDER BY order_month
    """)
