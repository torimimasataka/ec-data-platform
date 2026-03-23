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
    """Raw monthly revenue/orders per category (for client-side filtering)."""
    return run_query(f"""
        SELECT
            product_category_name_english,
            order_month,
            sum_price_month,
            cnt_orders_month
        FROM `{PROJECT}.{DS_APP}.app_category_performance`
        ORDER BY order_month
    """)


def load_geo_monthly() -> pd.DataFrame:
    """Raw monthly orders/revenue per state (for client-side filtering)."""
    return run_query(f"""
        SELECT
            customer_state,
            state_name_en,
            order_month,
            cnt_orders_month,
            sum_price_month
        FROM `{PROJECT}.{DS_APP}.app_geo_summary`
        ORDER BY order_month
    """)
