import streamlit as st
import streamlit.components.v1 as components
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from utils.bigquery import (
    load_summary_kpi,
    load_category_monthly,
    load_geo_monthly,
    load_category_customer_kpi,
    load_state_customer_kpi,
    load_cross_monthly,
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
# Color palette
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

# Pie chart color palette (orange gradient + gray for Others)
PIE_COLORS = [
    "#E8743B", "#D45F20", "#F5A07A", "#C04B10",
    "#F5C6A8", "#A03808", "#FAE0D0", "#8C3208", "#BBBBBB",
]

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

/* Slicer bordered container */
[data-testid="stVerticalBlockBorderWrapper"] {{
    border-color: {C['border']} !important;
    border-radius: 10px !important;
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
    color: {C['gray_dark']} !important;
}}
[data-testid="stSelectbox"] [data-baseweb="select"] > div:hover,
[data-testid="stMultiSelect"] [data-baseweb="select"] > div:hover {{
    border-color: {C['gray_mid']} !important;
}}
/* Selectbox selected value text */
[data-testid="stSelectbox"] [data-baseweb="select"] span,
[data-testid="stSelectbox"] [data-baseweb="select"] div {{
    color: {C['gray_dark']} !important;
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

/* KPI columns — equal height via flex stretch */
[data-testid="stHorizontalBlock"]:has(.kpi-card) {{
    align-items: stretch !important;
}}
[data-testid="stHorizontalBlock"]:has(.kpi-card) > [data-testid="stColumn"] {{
    display: flex !important;
    flex-direction: column !important;
}}
[data-testid="stHorizontalBlock"]:has(.kpi-card) > [data-testid="stColumn"]
    > [data-testid="stVerticalBlock"] {{
    flex: 1 !important;
    display: flex !important;
    flex-direction: column !important;
}}
[data-testid="stHorizontalBlock"]:has(.kpi-card) .stMarkdown,
[data-testid="stHorizontalBlock"]:has(.kpi-card) .stMarkdown > div {{
    flex: 1 !important;
    display: flex !important;
    flex-direction: column !important;
    height: 100% !important;
}}
/* KPI card */
.kpi-card {{
    background: {C['gray_bg']};
    border-radius: 12px;
    padding: 20px 22px 18px;
    border: 1px solid {C['border']};
    box-sizing: border-box;
    height: 100%;
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

/* Month badge */
.month-badge {{
    display: inline-block;
    background: {C['orange']};
    color: #fff;
    border-radius: 4px;
    padding: 1px 10px;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.04em;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    vertical-align: middle;
    margin-left: 8px;
}}

/* Muted button (Clear selection) */
[data-testid="stButton"] > button {{
    background-color: {C['white']} !important;
    border: 1px solid {C['border']} !important;
    color: {C['gray_mid']} !important;
    font-size: 11px !important;
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif !important;
    border-radius: 6px !important;
    font-weight: 500 !important;
}}
[data-testid="stButton"] > button:hover {{
    background-color: {C['gray_bg']} !important;
    border-color: {C['gray_mid']} !important;
    color: {C['gray_dark']} !important;
}}
/* Multiselect — show placeholder/value text */
[data-testid="stMultiSelect"] [data-baseweb="select"] span,
[data-testid="stMultiSelect"] [data-baseweb="select"] > div > div:first-child > div {{
    color: {C['gray_mid']} !important;
}}
[data-testid="stMultiSelect"] input::placeholder {{
    color: {C['gray_mid']} !important;
    opacity: 1 !important;
}}
/* Pie / chart section bottom spacing */
[data-testid="stVerticalBlock"] > [data-testid="stVerticalBlock"]:last-child {{
    padding-bottom: 32px;
}}
</style>
""", unsafe_allow_html=True)

# ── Scroll position preservation across reruns ──────────────────────────────
components.html("""
<script>
(function() {
    const KEY = 'ec_scroll';
    const w = window.parent;
    // Use PARENT's sessionStorage (survives iframe reloads on each rerun)
    const ss = w.sessionStorage;

    function getEl() {
        const d = w.document;
        return d.querySelector('[data-testid="stAppViewContainer"]')
            || d.querySelector('section.main') || d.body;
    }

    // ── Block Streamlit's scroll-to-top on rerun ────────────────────────────
    if (!w._ecScrollPatched) {
        w._ecScrollPatched = true;
        // Override window.scrollTo / window.scroll
        ['scrollTo', 'scroll'].forEach(fn => {
            const orig = w[fn].bind(w);
            w[fn] = function(x, y) {
                const saved = parseInt(ss.getItem(KEY) || '0');
                const toTop = (typeof y === 'number' && y === 0 && saved > 50)
                           || (typeof x === 'object' && x !== null && x.top === 0 && saved > 50);
                if (toTop) return;
                orig.apply(w, arguments);
            };
        });
    }

    // ── Also intercept scrollTop setter on the container ────────────────────
    // Re-patch on every render (element may have lost its custom descriptor)
    setTimeout(() => {
        const el = getEl();
        if (el && !el._ecPatched) {
            el._ecPatched = true;
            const proto = Object.getPrototypeOf(el);
            const desc = Object.getOwnPropertyDescriptor(proto, 'scrollTop')
                      || Object.getOwnPropertyDescriptor(w.HTMLElement.prototype, 'scrollTop');
            if (desc && desc.set) {
                Object.defineProperty(el, 'scrollTop', {
                    set(v) {
                        const saved = parseInt(ss.getItem(KEY) || '0');
                        if (v === 0 && saved > 50) return;
                        desc.set.call(this, v);
                    },
                    get: desc.get,
                    configurable: true,
                });
            }
        }
    }, 100);

    // ── Save scroll position every 200ms ────────────────────────────────────
    setInterval(() => {
        const el = getEl();
        if (el && el.scrollTop > 0) ss.setItem(KEY, el.scrollTop);
    }, 200);
})();
</script>
""", height=1)

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
    return f"¥{v:.1f}"

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

def _filtered_customer_kpi(df_cust, key_col, selected_keys, order_month):
    """カテゴリ or 州フィルター時のユニーク顧客数・リピート率を返す。
    複数キー選択時は cnt_unique を合算（わずかに重複計上の可能性あり）。
    Returns: (unique_customers: int|None, repeat_rate: float|None)
    """
    m_str = pd.Timestamp(order_month).strftime("%Y-%m")
    sub = df_cust[df_cust["order_month"].dt.strftime("%Y-%m") == m_str]
    if selected_keys:
        sub = sub[sub[key_col].isin(selected_keys)]
    if sub.empty:
        return None, None
    uc = int(sub["cnt_unique_customers_month"].sum())
    rc = int(sub["cnt_repeat_customers_month"].sum())
    rr = rc / uc if uc > 0 else 0.0
    return uc, rr


def _kpi_latest_prev(df, month_str):
    df = df.reset_index(drop=True)
    if month_str:
        idxs = df.index[df["order_month"].dt.strftime("%Y-%m") == month_str].tolist()
        if idxs:
            pos = idxs[0]
            return df.iloc[pos], (df.iloc[pos - 1] if pos > 0 else None)
        return None, None
    return (df.iloc[-1] if not df.empty else None,
            df.iloc[-2] if len(df) > 1 else None)


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
    df_cat_cust    = load_category_customer_kpi()
    df_state_cust  = load_state_customer_kpi()
    df_cross_all   = load_cross_monthly()

    for df in [df_kpi_all, df_cat_monthly, df_geo_monthly,
               df_cat_cust, df_state_cust, df_cross_all]:
        df["order_month"] = pd.to_datetime(df["order_month"])


# ── Available filter options ─────────────────
available_years = sorted(df_kpi_all["order_month"].dt.year.unique().tolist(), reverse=True)
latest_year     = available_years[0]

period_options = [str(y) for y in available_years] + ["Last 12 months", "Last 6 months", "All time"]

all_cats   = sorted(df_cat_monthly["product_category_name_english"].dropna().unique().tolist())
all_states = sorted(df_geo_monthly["state_name_en"].dropna().unique().tolist())

# ── Slicer bar ───────────────────────────────
with st.container(border=True):
    fc1, fc2, fc3 = st.columns([2, 2, 2], gap="small")
    with fc1:
        sel_period = st.selectbox(
            "Period",
            options=period_options,
            index=0,
        )
    with fc2:
        sel_cats = st.multiselect(
            "Category",
            options=all_cats,
            default=[],
            placeholder="All",
        )
    with fc3:
        sel_states = st.multiselect(
            "State",
            options=all_states,
            default=[],
            placeholder="All",
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
else:
    mask = pd.Series([True] * len(df_kpi_all), index=df_kpi_all.index)

df_kpi  = df_kpi_all[mask].sort_values("order_month").reset_index(drop=True)
df_catm = df_cat_monthly[df_cat_monthly["order_month"].isin(df_kpi["order_month"])]
df_geom = df_geo_monthly[df_geo_monthly["order_month"].isin(df_kpi["order_month"])]
df_cross = df_cross_all[df_cross_all["order_month"].isin(df_kpi["order_month"])]

# ── Apply category / state filter ───────────
if sel_cats:
    df_catm  = df_catm[df_catm["product_category_name_english"].isin(sel_cats)]
    df_cross = df_cross[df_cross["product_category_name_english"].isin(sel_cats)]
if sel_states:
    df_geom  = df_geom[df_geom["state_name_en"].isin(sel_states)]
    df_cross = df_cross[df_cross["state_name_en"].isin(sel_states)]

# ── Monthly trend data ───────────────────────
cat_or_state_filtered = bool(sel_cats or sel_states)

if sel_cats and sel_states:
    # 両フィルター: クロステーブルで集計
    df_trend = (
        df_cross
        .groupby("order_month", as_index=False)
        .agg(sum_price_month=("sum_price_month", "sum"), cnt_orders_month=("cnt_orders_month", "sum"))
        .sort_values("order_month")
    )
    df_trend["avg_review_score_month"] = float("nan")
elif sel_cats:
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

# ── Session state: selected month + chart key version ───────────────────────
if "sel_month_str" not in st.session_state:
    st.session_state["sel_month_str"] = None
if "chart_key_v" not in st.session_state:
    st.session_state["chart_key_v"] = 0
_valid_months = {pd.Timestamp(m).strftime("%Y-%m") for m in df_trend["order_month"]}
if st.session_state["sel_month_str"] and st.session_state["sel_month_str"] not in _valid_months:
    st.session_state["sel_month_str"] = None
sel_month_str = st.session_state["sel_month_str"]

# ──────────────────────────────────────────────
# KPI cards
# ──────────────────────────────────────────────
_latest, _prev = _kpi_latest_prev(df_trend, sel_month_str)

st.markdown('<div class="section-label">Key Metrics</div>', unsafe_allow_html=True)
c1, c2, c3, c4, c5, c6 = st.columns(6, gap="small")

if _latest is None:
    for col, lbl in zip([c1, c2, c3, c4, c5, c6],
                        ["Monthly Revenue", "Orders", "Avg Order Value",
                         "Unique Customers", "Repeat Rate", "YTD Revenue"]):
        with col:
            st.markdown(kpi_card(lbl, "—"), unsafe_allow_html=True)
else:
    pv = lambda col: _prev[col] if _prev is not None and col in _prev.index else None
    rev  = _latest["sum_price_month"]
    ords = _latest["cnt_orders_month"]
    aov  = rev / ords if ords > 0 else 0
    cur_year      = pd.Timestamp(_latest["order_month"]).year
    cur_month_str = pd.Timestamp(_latest["order_month"]).strftime("%Y-%m")
    ytd = df_trend[
        (pd.to_datetime(df_trend["order_month"]).dt.year == cur_year) &
        (pd.to_datetime(df_trend["order_month"]).dt.strftime("%Y-%m") <= cur_month_str)
    ]["sum_price_month"].sum()
    prev_rev  = pv("sum_price_month")
    prev_ords = pv("cnt_orders_month")
    prev_aov  = (_latest["sum_price_month"] / _latest["cnt_orders_month"]
                 if _prev is not None and pv("cnt_orders_month") and pv("cnt_orders_month") > 0
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
            if sel_cats:
                uc_f, _ = _filtered_customer_kpi(
                    df_cat_cust, "product_category_name_english", sel_cats, _latest["order_month"])
            else:
                uc_f, _ = _filtered_customer_kpi(
                    df_state_cust, "state_name_en", sel_states, _latest["order_month"])
            val = f"{uc_f:,.0f}" if uc_f is not None else "—"
            st.markdown(kpi_card("Unique Customers", val), unsafe_allow_html=True)
        else:
            uc = _latest["cnt_active_customers_month"]
            st.markdown(kpi_card("Unique Customers", f"{uc:,.0f}",
                                 delta_html(uc, pv("cnt_active_customers_month"))), unsafe_allow_html=True)
    with c5:
        if cat_or_state_filtered:
            if sel_cats:
                _, rr_f = _filtered_customer_kpi(
                    df_cat_cust, "product_category_name_english", sel_cats, _latest["order_month"])
            else:
                _, rr_f = _filtered_customer_kpi(
                    df_state_cust, "state_name_en", sel_states, _latest["order_month"])
            val = f"{rr_f*100:.1f}%" if rr_f is not None else "—"
            st.markdown(kpi_card("Repeat Rate", val), unsafe_allow_html=True)
        else:
            rr = _latest["repeat_customer_rate_month"]
            st.markdown(kpi_card("Repeat Rate", f"{rr*100:.1f}%",
                                 delta_html(rr, pv("repeat_customer_rate_month"))), unsafe_allow_html=True)
    with c6:
        st.markdown(kpi_card("YTD Revenue", fmt_currency(ytd)), unsafe_allow_html=True)

st.divider()

# ──────────────────────────────────────────────
# Monthly trend chart (clickable)
# ──────────────────────────────────────────────
st.markdown('<div class="section-label">Monthly Trends</div>', unsafe_allow_html=True)

# Color bars: highlight selected month, dim others
bar_colors = []
for m in df_trend["order_month"]:
    m_str = pd.Timestamp(m).strftime("%Y-%m")
    if sel_month_str:
        bar_colors.append(C["orange"] if m_str == sel_month_str else C["orange_light"])
    else:
        bar_colors.append(C["orange"])

fig_trend = make_subplots(specs=[[{"secondary_y": True}]])
fig_trend.add_trace(go.Bar(
    x=df_trend["order_month"], y=df_trend["sum_price_month"],
    name="Revenue", marker_color=bar_colors, marker_line_width=0, opacity=0.9,
    hovertemplate="%{x|%b %Y}<br>Revenue: ¥%{y:,.0f}<extra></extra>",
    # Disable Plotly's built-in selection dimming; we handle color manually
    selected=dict(marker=dict(opacity=0.9)),
    unselected=dict(marker=dict(opacity=0.9)),
), secondary_y=False)
fig_trend.add_trace(go.Scatter(
    x=df_trend["order_month"], y=df_trend["cnt_orders_month"],
    name="Orders", mode="lines+markers",
    line=dict(color=C["gray_mid"], width=2),
    marker=dict(size=4, color=C["gray_mid"]),
    hovertemplate="%{x|%b %Y}<br>Orders: %{y:,.0f}<extra></extra>",
    selected=dict(marker=dict(opacity=1, size=4)),
    unselected=dict(marker=dict(opacity=1, size=4)),
), secondary_y=True)

fig_trend.update_layout(
    **BASE_LAYOUT,
    height=300,
    bargap=0.35,
    margin=dict(l=4, r=56, t=8, b=4),
    dragmode=False,  # disable drag-select box; use point clicks only
    legend=dict(
        orientation="h", yanchor="top", y=-0.12, xanchor="left", x=0,
        font=dict(size=11, color=C["gray_mid"]),
        bgcolor="rgba(0,0,0,0)",
    ),
)
apply_axes(fig_trend, secondary=True)
fig_trend.update_yaxes(tickprefix="¥", tickformat=",.0f", secondary_y=False)
fig_trend.update_yaxes(tickformat=",.0f", secondary_y=True)

# Header row: title + clear button
_badge = (
    f'<span class="month-badge">{pd.Timestamp(sel_month_str).strftime("%b %Y")}</span>'
    if sel_month_str else ""
)
_hint = "Click a bar to drill into that month" if not sel_month_str else "Click another bar to change · click selected bar to deselect"
trend_header_col, trend_clear_col = st.columns([9, 1])
with trend_header_col:
    st.markdown(f"""
<div style="margin-bottom:4px">
  <span style="font-size:15px;font-weight:700;color:#1A1A1A;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">Revenue &amp; Order Trends{_badge}</span><br>
  <span style="font-size:12px;color:#6B6B6B;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">{_hint}</span>
</div>
""", unsafe_allow_html=True)
with trend_clear_col:
    if sel_month_str:
        if st.button("✕ Clear", key="clear_month", use_container_width=True):
            st.session_state["sel_month_str"] = None
            st.session_state["chart_key_v"] += 1  # force new chart widget (clears Plotly selection)

# Render chart with click selection enabled
trend_event = st.plotly_chart(
    fig_trend,
    use_container_width=True,
    on_select="rerun",
    selection_mode="points",
    key=f"trend_chart_{st.session_state['chart_key_v']}",
    config={"displayModeBar": False},
)

# Process click event — update session state and rerun to sync bar colors + KPI
if trend_event and trend_event.selection and trend_event.selection.points:
    try:
        raw_x   = trend_event.selection.points[0]["x"]
        clicked = pd.Timestamp(raw_x).strftime("%Y-%m")
    except Exception:
        clicked = None
    if clicked and clicked != st.session_state["sel_month_str"]:
        st.session_state["sel_month_str"] = clicked
        st.rerun()

# Re-read sel_month_str (may differ from top of script after Clear button)
sel_month_str = st.session_state["sel_month_str"]

st.divider()

# ──────────────────────────────────────────────
# Drill-down filter: apply selected month to
# category & geo data for all charts below
# ──────────────────────────────────────────────
if sel_month_str:
    df_catm_drill  = df_catm[df_catm["order_month"].dt.strftime("%Y-%m") == sel_month_str]
    df_geom_drill  = df_geom[df_geom["order_month"].dt.strftime("%Y-%m") == sel_month_str]
    df_cross_drill = df_cross[df_cross["order_month"].dt.strftime("%Y-%m") == sel_month_str]
    drill_label    = pd.Timestamp(sel_month_str).strftime("%b %Y")
else:
    df_catm_drill  = df_catm
    df_geom_drill  = df_geom
    df_cross_drill = df_cross
    drill_label    = sel_period

# Top 10 aggregation
# カテゴリTOP10: 州フィルターがある場合はクロステーブルで州絞り込みを反映
_cat_src = df_cross_drill if sel_states else df_catm_drill
df_cat = (
    _cat_src
    .groupby("product_category_name_english", as_index=False)
    .agg(total_revenue=("sum_price_month", "sum"), total_orders=("cnt_orders_month", "sum"))
    .sort_values("total_revenue", ascending=False)
    .head(10)
)
# 州TOP10: カテゴリフィルターがある場合はクロステーブルでカテゴリ絞り込みを反映
_geo_src = df_cross_drill if sel_cats else df_geom_drill
df_geo = (
    _geo_src
    .groupby(["customer_state", "state_name_en"], as_index=False)
    .agg(total_orders=("cnt_orders_month", "sum"), total_revenue=("sum_price_month", "sum"))
    .sort_values("total_orders", ascending=False)
    .head(10)
)

# Full aggregation for pie charts (all categories / states, not just top 10)
df_cat_all = (
    _cat_src
    .groupby("product_category_name_english", as_index=False)
    .agg(total_revenue=("sum_price_month", "sum"))
    .sort_values("total_revenue", ascending=False)
)
df_geo_all = (
    _geo_src
    .groupby("state_name_en", as_index=False)
    .agg(total_orders=("cnt_orders_month", "sum"))
    .sort_values("total_orders", ascending=False)
)

# ──────────────────────────────────────────────
# Category Top10 + State ranking
# ──────────────────────────────────────────────
col_left, col_right = st.columns(2, gap="large")

with col_left:
    st.markdown('<div class="section-label">Category Performance</div>', unsafe_allow_html=True)

    cat_y  = df_cat["product_category_name_english"][::-1]
    cat_x  = df_cat["total_revenue"][::-1]
    colors = [C["orange"] if i == len(cat_x) - 1 else C["orange_light"] for i in range(len(cat_x))]

    fig_cat = go.Figure(go.Bar(
        x=cat_x, y=cat_y, orientation="h",
        marker_color=colors, marker_line_width=0,
        text=cat_x.apply(fmt_currency),
        textposition="outside",
        textfont=dict(size=11, color=C["gray_mid"]),
        cliponaxis=False,
        hovertemplate="%{y}<br>Revenue: ¥%{x:,.0f}<extra></extra>",
    ))
    fig_cat.update_layout(
        **BASE_LAYOUT, height=380, margin=dict(l=4, r=180, t=64, b=4),
        title=dict(
            text=f"<b>Top 10 Categories</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>Revenue · {drill_label}</span>",
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

    geo_y      = df_geo["state_name_en"][::-1]
    geo_x      = df_geo["total_orders"][::-1]
    geo_colors = [C["orange"] if i == len(geo_x) - 1 else C["gray_light"] for i in range(len(geo_x))]

    fig_geo = go.Figure(go.Bar(
        x=geo_x, y=geo_y, orientation="h",
        marker_color=geo_colors, marker_line_width=0,
        text=geo_x.apply(lambda v: f"{v:,.0f}"),
        textposition="outside",
        textfont=dict(size=11, color=C["gray_mid"]),
        cliponaxis=False,
        hovertemplate="%{y}<br>Orders: %{x:,.0f}<extra></extra>",
    ))
    fig_geo.update_layout(
        **BASE_LAYOUT, height=380, margin=dict(l=4, r=180, t=64, b=4),
        title=dict(
            text=f"<b>Top 10 States by Orders</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>Order volume · {drill_label}</span>",
            font=dict(size=15, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            x=0, xanchor="left", pad=dict(l=4, t=4),
        ),
    )
    fig_geo.update_xaxes(showgrid=False, showticklabels=False, showline=False, zeroline=False)
    fig_geo.update_yaxes(showgrid=False, showline=False, zeroline=False,
                         tickfont=dict(size=12, color=C["gray_dark"]))
    st.plotly_chart(fig_geo, use_container_width=True, config={"displayModeBar": False})

st.divider()

# ──────────────────────────────────────────────
# Share pies: Category revenue share + State order share
# ──────────────────────────────────────────────
st.markdown('<div class="section-label">Revenue &amp; Order Share</div>', unsafe_allow_html=True)

PIE_TOP_N = 8

# Category pie: top N + Others
df_cat_pie = df_cat_all.head(PIE_TOP_N).copy()
others_rev = df_cat_all.iloc[PIE_TOP_N:]["total_revenue"].sum()
if others_rev > 0:
    df_cat_pie = pd.concat([
        df_cat_pie,
        pd.DataFrame([{"product_category_name_english": "Others", "total_revenue": others_rev}]),
    ], ignore_index=True)

# State pie: top N + Others
df_geo_pie = df_geo_all.head(PIE_TOP_N).copy()
others_ord = df_geo_all.iloc[PIE_TOP_N:]["total_orders"].sum()
if others_ord > 0:
    df_geo_pie = pd.concat([
        df_geo_pie,
        pd.DataFrame([{"state_name_en": "Others", "total_orders": others_ord}]),
    ], ignore_index=True)

pie_left, pie_right = st.columns(2, gap="large")

with pie_left:
    fig_pie_cat = go.Figure(go.Pie(
        labels=df_cat_pie["product_category_name_english"],
        values=df_cat_pie["total_revenue"],
        hole=0.52,
        marker=dict(
            colors=PIE_COLORS[:len(df_cat_pie)],
            line=dict(color="#FFFFFF", width=2),
        ),
        textinfo="percent",
        textfont=dict(size=11, family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
        hovertemplate="%{label}<br>Revenue: ¥%{value:,.0f}<br>Share: %{percent}<extra></extra>",
        sort=False,
    ))
    fig_pie_cat.update_layout(
        **{k: v for k, v in BASE_LAYOUT.items() if k != "hovermode"},
        height=380,
        margin=dict(l=4, r=4, t=64, b=4),
        title=dict(
            text=f"<b>Category Revenue Share</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>{drill_label}</span>",
            font=dict(size=15, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            x=0, xanchor="left", pad=dict(l=4, t=4),
        ),
        legend=dict(
            orientation="v", yanchor="middle", y=0.5, xanchor="left", x=1.02,
            font=dict(size=11, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            bgcolor="rgba(0,0,0,0)",
        ),
        showlegend=True,
    )
    st.plotly_chart(fig_pie_cat, use_container_width=True, config={"displayModeBar": False})

with pie_right:
    fig_pie_geo = go.Figure(go.Pie(
        labels=df_geo_pie["state_name_en"],
        values=df_geo_pie["total_orders"],
        hole=0.52,
        marker=dict(
            colors=PIE_COLORS[:len(df_geo_pie)],
            line=dict(color="#FFFFFF", width=2),
        ),
        textinfo="percent",
        textfont=dict(size=11, family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
        hovertemplate="%{label}<br>Orders: %{value:,.0f}<br>Share: %{percent}<extra></extra>",
        sort=False,
    ))
    fig_pie_geo.update_layout(
        **{k: v for k, v in BASE_LAYOUT.items() if k != "hovermode"},
        height=380,
        margin=dict(l=4, r=4, t=64, b=4),
        title=dict(
            text=f"<b>State Order Share</b><br><span style='font-size:12px;color:#6B6B6B;font-weight:normal'>{drill_label}</span>",
            font=dict(size=15, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            x=0, xanchor="left", pad=dict(l=4, t=4),
        ),
        legend=dict(
            orientation="v", yanchor="middle", y=0.5, xanchor="left", x=1.02,
            font=dict(size=11, color=C["gray_dark"], family="'Helvetica Neue', Helvetica, Arial, sans-serif"),
            bgcolor="rgba(0,0,0,0)",
        ),
        showlegend=True,
    )
    st.plotly_chart(fig_pie_geo, use_container_width=True, config={"displayModeBar": False})
