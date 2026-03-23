import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from utils.bigquery import (
    load_summary_kpi,
    load_category_monthly,
    load_geo_monthly,
)

# ──────────────────────────────────────────────
# Page config
# ──────────────────────────────────────────────
st.set_page_config(
    page_title="EC Sales Dashboard",
    page_icon="",
    layout="wide",
    initial_sidebar_state="collapsed",
)

# ──────────────────────────────────────────────
# Color palette  (white / gray / orange / red)
# ──────────────────────────────────────────────
C = {
    "orange"      : "#E8743B",
    "orange_light": "#F5C6A8",
    "orange_pale" : "#FDF0E8",
    "gray_dark"   : "#1A1A1A",
    "gray_mid"    : "#6B6B6B",
    "gray_light"  : "#E8E8E8",
    "gray_bg"     : "#F5F5F5",
    "white"       : "#FFFFFF",
    "red"         : "#CC3333",
    "green"       : "#2E7D32",
    "border"      : "#DEDEDE",
}

# ──────────────────────────────────────────────
# CSS
# ──────────────────────────────────────────────
st.markdown(f"""
<style>
/* Force white background */
html, body,
[data-testid="stAppViewContainer"],
[data-testid="stAppViewBlockContainer"],
[data-testid="block-container"],
.main, section.main {{
    background-color: {C['white']} !important;
    color: {C['gray_dark']};
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}}
[data-testid="stHeader"] {{ background: {C['white']} !important; }}
#MainMenu, footer, header {{ visibility: hidden; }}
.block-container {{ padding: 48px 64px 64px; max-width: 1440px; }}

/* Filter box container (via :has trigger) */
[data-testid="stVerticalBlock"]:has(.filter-box-trigger) {{
    background: {C['gray_bg']};
    border: 1px solid {C['border']};
    border-radius: 12px;
    padding: 16px 20px 8px !important;
    margin-bottom: 24px;
}}
/* Slicer labels */
[data-testid="stSelectbox"] label,
[data-testid="stMultiSelect"] label {{
    font-size: 10px !important;
    font-weight: 700 !important;
    letter-spacing: 0.1em !important;
    text-transform: uppercase !important;
    color: {C['gray_mid']} !important;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
    margin-bottom: 4px !important;
}}
/* Selectbox & Multiselect — unified input style */
[data-testid="stSelectbox"] [data-baseweb="select"] > div,
[data-testid="stMultiSelect"] [data-baseweb="select"] > div {{
    background: {C['white']} !important;
    border: 1px solid {C['border']} !important;
    border-radius: 8px !important;
    min-height: 40px !important;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
    font-size: 13px !important;
}}
[data-testid="stSelectbox"] [data-baseweb="select"] > div:hover,
[data-testid="stMultiSelect"] [data-baseweb="select"] > div:hover {{
    border-color: {C['gray_mid']} !important;
}}
/* Show dropdown chevron in gray */
[data-testid="stSelectbox"] svg,
[data-testid="stMultiSelect"] [data-baseweb="select"] > div > div:last-child svg {{
    fill: {C['gray_mid']} !important;
    opacity: 1 !important;
    display: block !important;
}}
/* Multiselect tags — muted style matching selectbox */
[data-baseweb="tag"] {{
    background-color: #EDECEA !important;
    border: none !important;
    border-radius: 5px !important;
    margin: 2px 3px !important;
    padding: 0 6px !important;
}}
[data-baseweb="tag"] span {{
    color: {C['gray_dark']} !important;
    font-size: 11px !important;
    font-weight: 500 !important;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
}}
[data-baseweb="tag"] svg {{
    fill: #ADADAD !important;
}}
/* Dropdown list items */
[data-baseweb="menu"] li {{
    font-size: 13px !important;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
    color: {C['gray_dark']} !important;
}}

/* Page header */
.page-header {{ margin-bottom: 44px; border-bottom: 1px solid {C['border']}; padding-bottom: 20px; }}
.page-header h1 {{
    font-size: 28px; font-weight: 700; letter-spacing: -0.3px;
    color: {C['gray_dark']}; margin: 0 0 6px;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}}
.page-header p {{
    font-size: 14px; color: {C['gray_mid']}; margin: 0;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}}

/* Section label */
.section-label {{
    font-size: 10px; font-weight: 700; letter-spacing: 0.12em;
    text-transform: uppercase; color: {C['gray_mid']}; margin-bottom: 14px;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}}

/* KPI card */
.kpi-card {{
    background: {C['gray_bg']};
    border-radius: 12px;
    padding: 20px 22px 18px;
    border: 1px solid {C['border']};
    min-height: 120px;
    box-sizing: border-box;
}}
.kpi-label {{
    font-size: 11px; font-weight: 600; letter-spacing: 0.04em;
    text-transform: uppercase; color: {C['gray_mid']};
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    margin-bottom: 10px;
}}
.kpi-value {{
    font-size: 26px; font-weight: 700; color: {C['gray_dark']};
    letter-spacing: -0.5px; line-height: 1;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}}
.kpi-delta-pos {{ font-size: 11px; font-weight: 600; color: {C['green']}; margin-top: 6px; }}
.kpi-delta-neg {{ font-size: 11px; font-weight: 600; color: {C['red']};   margin-top: 6px; }}
.kpi-delta-neu {{ font-size: 11px; color: {C['gray_mid']};                margin-top: 6px; }}

/* Chart wrapper */
.chart-wrap {{
    background: {C['white']};
    border: 1px solid {C['border']};
    border-radius: 12px;
    padding: 24px 24px 12px;
}}
.chart-title {{
    font-size: 15px; font-weight: 700; color: {C['gray_dark']};
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; margin-bottom: 2px;
}}
.chart-sub {{
    font-size: 12px; color: {C['gray_mid']};
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; margin-bottom: 16px;
}}

/* Divider */
.divider {{ height: 1px; background: {C['border']}; margin: 32px 0; }}
</style>
""", unsafe_allow_html=True)

# ──────────────────────────────────────────────
# Plotly base layout
# ──────────────────────────────────────────────
BASE_LAYOUT = dict(
    paper_bgcolor="#FFFFFF",
    plot_bgcolor="#FFFFFF",
    font=dict(family="'Helvetica Neue', Helvetica, Arial, sans-serif", color=C["gray_dark"]),
    hovermode="x unified",
)

def apply_axes(fig, secondary=False):
    fig.update_xaxes(
        showgrid=False, showline=False, zeroline=False,
        tickfont=dict(size=11, color=C["gray_mid"]),
    )
    fig.update_yaxes(
        showgrid=True, gridcolor=C["gray_light"], gridwidth=1,
        showline=False, zeroline=False,
        tickfont=dict(size=11, color=C["gray_mid"]),
        secondary_y=False,
    )
    if secondary:
        fig.update_yaxes(
            showgrid=False, showline=False, zeroline=False,
            tickfont=dict(size=11, color=C["gray_mid"]),
            secondary_y=True,
        )


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────
def fmt_currency(v: float) -> str:
    if v >= 1_000_000:
        return f"¥{v/1_000_000:.1f}M"
    if v >= 1_000:
        return f"¥{v/1_000:.1f}K"
    return f"¥{v:,.0f}"

def kpi_card(label: str, value: str, delta_html: str = "") -> str:
    return f"""
    <div class="kpi-card">
        <div class="kpi-label">{label}</div>
        <div class="kpi-value">{value}</div>
        <div>{delta_html}</div>
    </div>"""

def delta_html(current, prev) -> str:
    if prev is None or prev == 0 or pd.isna(prev):
        return ""
    d = (current - prev) / abs(prev)
    sign, cls = ("▲", "kpi-delta-pos") if d >= 0 else ("▼", "kpi-delta-neg")
    return f'<div class="{cls}">{sign} {abs(d)*100:.1f}% vs prev</div>'


# ──────────────────────────────────────────────
# Header
# ──────────────────────────────────────────────
st.markdown("""
<div class="page-header">
    <h1>EC Sales Dashboard</h1>
    <p>Brazilian e-commerce — Sales overview &amp; trends</p>
</div>""", unsafe_allow_html=True)

# ──────────────────────────────────────────────
# Load all raw data (cached, no filter)
# ──────────────────────────────────────────────
with st.spinner("Loading data..."):
    df_kpi_all     = load_summary_kpi()
    df_cat_monthly = load_category_monthly()
    df_geo_monthly = load_geo_monthly()

    df_kpi_all["order_month"]     = pd.to_datetime(df_kpi_all["order_month"])
    df_cat_monthly["order_month"] = pd.to_datetime(df_cat_monthly["order_month"])
    df_geo_monthly["order_month"] = pd.to_datetime(df_geo_monthly["order_month"])

# ── Available filter options ─────────────────
available_years = sorted(df_kpi_all["order_month"].dt.year.unique().tolist(), reverse=True)
latest_year     = available_years[0]

# Period options: latest year first, then older years, then relative presets
period_options = [str(y) for y in available_years] + ["Last 12 months", "Last 6 months", "All time"]

all_cats   = sorted(df_cat_monthly["product_category_name_english"].dropna().unique().tolist())
all_states = sorted(df_geo_monthly["state_name_en"].dropna().unique().tolist())

# ── Slicer bar ───────────────────────────────
with st.container():
    # hidden trigger lets CSS :has() detect and style this container
    st.markdown('<span class="filter-box-trigger" style="display:none"></span>', unsafe_allow_html=True)
    fc1, fc2, fc3 = st.columns([2, 2, 2], gap="small")
    with fc1:
        sel_period = st.selectbox(
            "Period",
            options=period_options,
            index=0,   # default: latest year
        )
    with fc2:
        sel_cats = st.multiselect(
            "Category",
            options=all_cats,
            default=[],
            placeholder="All categories",
        )
    with fc3:
        sel_states = st.multiselect(
            "State",
            options=all_states,
            default=[],
            placeholder="All states",
        )

# ── Apply period filter ──────────────────────
max_month = df_kpi_all["order_month"].max()

if sel_period.isdigit():
    year = int(sel_period)
    mask = df_kpi_all["order_month"].dt.year == year
elif sel_period == "Last 6 months":
    cutoff = max_month - pd.DateOffset(months=5)
    mask = df_kpi_all["order_month"] >= cutoff
elif sel_period == "Last 12 months":
    cutoff = max_month - pd.DateOffset(months=11)
    mask = df_kpi_all["order_month"] >= cutoff
else:  # All time
    mask = pd.Series([True] * len(df_kpi_all), index=df_kpi_all.index)

df_kpi  = df_kpi_all[mask].sort_values("order_month").reset_index(drop=True)
df_catm = df_cat_monthly[df_cat_monthly["order_month"].isin(df_kpi["order_month"])]
df_geom = df_geo_monthly[df_geo_monthly["order_month"].isin(df_kpi["order_month"])]

# ── Apply category / state filter ───────────
if sel_cats:
    df_catm = df_catm[df_catm["product_category_name_english"].isin(sel_cats)]
if sel_states:
    df_geom = df_geom[df_geom["state_name_en"].isin(sel_states)]

# ── Aggregated bar chart data (top 10) ──────
df_cat = (
    df_catm
    .groupby("product_category_name_english", as_index=False)
    .agg(total_revenue=("sum_price_month", "sum"), total_orders=("cnt_orders_month", "sum"))
    .sort_values("total_revenue", ascending=False)
    .head(10)
)
df_geo = (
    df_geom
    .groupby(["customer_state", "state_name_en"], as_index=False)
    .agg(total_orders=("cnt_orders_month", "sum"), total_revenue=("sum_price_month", "sum"))
    .sort_values("total_orders", ascending=False)
    .head(10)
)

# ── Monthly trend data ───────────────────────
# When category/state filter active → aggregate filtered monthly data
# Review Score only available from summary_kpi (no category/state breakdown)
cat_or_state_filtered = bool(sel_cats or sel_states)

if sel_cats:
    df_trend = (
        df_catm
        .groupby("order_month", as_index=False)
        .agg(sum_price_month=("sum_price_month", "sum"), cnt_orders_month=("cnt_orders_month", "sum"))
        .sort_values("order_month")
    )
    df_trend["avg_review_score_month"] = float("nan")
elif sel_states:
    df_trend = (
        df_geom
        .groupby("order_month", as_index=False)
        .agg(sum_price_month=("sum_price_month", "sum"), cnt_orders_month=("cnt_orders_month", "sum"))
        .sort_values("order_month")
    )
    df_trend["avg_review_score_month"] = float("nan")
else:
    df_trend = df_kpi

latest = df_trend.iloc[-1] if not df_trend.empty else None
prev   = df_trend.iloc[-2] if len(df_trend) > 1 else None

# ──────────────────────────────────────────────
# KPI cards
# ──────────────────────────────────────────────
st.markdown('<div class="section-label">Key Metrics</div>', unsafe_allow_html=True)

c1, c2, c3, c4, c5, c6 = st.columns(6, gap="small")

if latest is None:
    # No data for current filter — show placeholder cards
    for col, lbl in zip([c1, c2, c3, c4, c5, c6],
                        ["Monthly Revenue", "Orders", "Avg Order Value",
                         "Unique Customers", "Repeat Rate", "YTD Revenue"]):
        with col:
            st.markdown(kpi_card(lbl, "—"), unsafe_allow_html=True)
else:
    pv = lambda col: prev[col] if prev is not None and col in prev.index else None

    rev   = latest["sum_price_month"]
    ords  = latest["cnt_orders_month"]
    aov   = rev / ords if ords > 0 else 0

    cur_year = pd.Timestamp(latest["order_month"]).year
    ytd = df_trend[pd.to_datetime(df_trend["order_month"]).dt.year == cur_year]["sum_price_month"].sum()

    prev_rev  = pv("sum_price_month")
    prev_ords = pv("cnt_orders_month")
    prev_aov  = (pv("sum_price_month") / pv("cnt_orders_month")
                 if prev is not None and pv("cnt_orders_month") and pv("cnt_orders_month") > 0
                 else None)

    with c1:
        st.markdown(kpi_card("Monthly Revenue", fmt_currency(rev),
                             delta_html(rev, prev_rev)), unsafe_allow_html=True)
    with c2:
        st.markdown(kpi_card("Orders", f"{ords:,.0f}",
                             delta_html(ords, prev_ords)), unsafe_allow_html=True)
    with c3:
        st.markdown(kpi_card("Avg Order Value", f"¥{aov:,.1f}",
                             delta_html(aov, prev_aov)), unsafe_allow_html=True)
    with c4:
        if cat_or_state_filtered:
            st.markdown(kpi_card("Unique Customers", "—"), unsafe_allow_html=True)
        else:
            uc = latest["cnt_active_customers_month"]
            st.markdown(kpi_card("Unique Customers", f"{uc:,.0f}",
                                 delta_html(uc, pv("cnt_active_customers_month"))), unsafe_allow_html=True)
    with c5:
        if cat_or_state_filtered:
            st.markdown(kpi_card("Repeat Rate", "—"), unsafe_allow_html=True)
        else:
            rr = latest["repeat_customer_rate_month"]
            st.markdown(kpi_card("Repeat Rate", f"{rr*100:.1f}%",
                                 delta_html(rr, pv("repeat_customer_rate_month"))), unsafe_allow_html=True)
    with c6:
        st.markdown(kpi_card("YTD Revenue", fmt_currency(ytd)), unsafe_allow_html=True)

st.markdown('<div class="divider"></div>', unsafe_allow_html=True)

# ──────────────────────────────────────────────
# Monthly trend
# ──────────────────────────────────────────────
st.markdown('<div class="section-label">Monthly Trends</div>', unsafe_allow_html=True)

fig_trend = make_subplots(specs=[[{"secondary_y": True}]])
fig_trend.add_trace(go.Bar(
    x=df_trend["order_month"], y=df_trend["sum_price_month"],
    name="Revenue", marker_color=C["orange"], marker_line_width=0, opacity=0.9,
    hovertemplate="%{x|%b %Y}<br>Revenue: ¥%{y:,.0f}<extra></extra>",
), secondary_y=False)
fig_trend.add_trace(go.Scatter(
    x=df_trend["order_month"], y=df_trend["cnt_orders_month"],
    name="Orders", mode="lines+markers",
    line=dict(color=C["gray_mid"], width=2),
    marker=dict(size=4, color=C["gray_mid"]),
    hovertemplate="%{x|%b %Y}<br>Orders: %{y:,.0f}<extra></extra>",
), secondary_y=True)

fig_trend.update_layout(
    **BASE_LAYOUT,
    height=300,
    bargap=0.35,
    margin=dict(l=4, r=56, t=8, b=4),
    legend=dict(
        orientation="h", yanchor="top", y=-0.12, xanchor="left", x=0,
        font=dict(size=11, color=C["gray_mid"]),
        bgcolor="rgba(0,0,0,0)",
    ),
)
apply_axes(fig_trend, secondary=True)
fig_trend.update_yaxes(tickprefix="¥", tickformat=",.0f", secondary_y=False)
fig_trend.update_yaxes(tickformat=",.0f", secondary_y=True)

st.markdown("""
<div style="margin-bottom:4px">
  <span style="font-size:15px;font-weight:700;color:#1A1A1A;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">Revenue &amp; Order Trends</span><br>
  <span style="font-size:12px;color:#6B6B6B;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">Monthly revenue (bars, left) &middot; Orders (gray line, right)</span>
</div>
""", unsafe_allow_html=True)
st.plotly_chart(fig_trend, use_container_width=True, config={"displayModeBar": False})

st.markdown('<div class="divider"></div>', unsafe_allow_html=True)

# ──────────────────────────────────────────────
# Category Top10 + State ranking
# ──────────────────────────────────────────────
col_left, col_right = st.columns(2, gap="large")

with col_left:
    st.markdown('<div class="section-label">Category Performance</div>', unsafe_allow_html=True)

    cat_y = df_cat["product_category_name_english"][::-1]
    cat_x = df_cat["total_revenue"][::-1]
    colors = [C["orange"] if i == len(cat_x) - 1 else C["orange_light"] for i in range(len(cat_x))]

    fig_cat = go.Figure(go.Bar(
        x=cat_x, y=cat_y, orientation="h",
        marker_color=colors, marker_line_width=0,
        text=cat_x.apply(fmt_currency),
        textposition="outside",
        textfont=dict(size=11, color=C["gray_mid"]),
        hovertemplate="%{y}<br>Revenue: ¥%{x:,.0f}<extra></extra>",
    ))
    fig_cat.update_layout(
        **BASE_LAYOUT, height=380, margin=dict(l=4, r=72, t=64, b=4),
        title=dict(
            text="<b>Top 10 Categories</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>Revenue by category for selected period</span>",
            font=dict(size=15, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            x=0, xanchor="left", pad=dict(l=4, t=4),
        ),
    )
    fig_cat.update_xaxes(showgrid=False, showticklabels=False, showline=False, zeroline=False)
    fig_cat.update_yaxes(showgrid=False, showline=False, zeroline=False,
                         tickfont=dict(size=12, color=C["gray_dark"]))
    st.plotly_chart(fig_cat, use_container_width=True, config={"displayModeBar": False})

with col_right:
    st.markdown('<div class="section-label">State Ranking</div>', unsafe_allow_html=True)

    geo_y = df_geo["state_name_en"][::-1]
    geo_x = df_geo["total_orders"][::-1]
    geo_colors = [C["orange"] if i == len(geo_x) - 1 else C["gray_light"] for i in range(len(geo_x))]

    fig_geo = go.Figure(go.Bar(
        x=geo_x, y=geo_y, orientation="h",
        marker_color=geo_colors, marker_line_width=0,
        text=geo_x.apply(lambda v: f"{v:,.0f}"),
        textposition="outside",
        textfont=dict(size=11, color=C["gray_mid"]),
        hovertemplate="%{y}<br>Orders: %{x:,.0f}<extra></extra>",
    ))
    fig_geo.update_layout(
        **BASE_LAYOUT, height=380, margin=dict(l=4, r=72, t=64, b=4),
        title=dict(
            text="<b>Top 10 States by Orders</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>Order volume by state for selected period</span>",
            font=dict(size=15, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            x=0, xanchor="left", pad=dict(l=4, t=4),
        ),
    )
    fig_geo.update_xaxes(showgrid=False, showticklabels=False, showline=False, zeroline=False)
    fig_geo.update_yaxes(showgrid=False, showline=False, zeroline=False,
                         tickfont=dict(size=12, color=C["gray_dark"]))
    st.plotly_chart(fig_geo, use_container_width=True, config={"displayModeBar": False})
