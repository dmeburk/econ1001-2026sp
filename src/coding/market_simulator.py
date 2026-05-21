import streamlit as st
import numpy as np
import matplotlib.pyplot as plt

st.title("⚖️ Market Simulator with Price & Quantity Restrictions — Correct Welfare")

# ----- Primitives
a_d = st.slider("Demand Intercept (a_d)", 5.0, 30.0, 20.0, step=0.5)
b_d = st.slider("Demand Slope (b_d)",   0.5, 3.0, 1.0,  step=0.1)
a_s = st.slider("Supply Intercept (a_s)", 0.0, 10.0, 2.0, step=0.5)
b_s = st.slider("Supply Slope (b_s)",   0.5, 3.0, 1.0,  step=0.1)

# Curves
P_d = lambda Q: a_d - b_d*Q     # demand price at Q
P_s = lambda Q: a_s + b_s*Q     # supply price at Q

# Integrals (areas under curves from 0 to Q)
A_d = lambda Q: a_d*Q - 0.5*b_d*Q**2   # ∫_0^Q P_d(q)dq
A_s = lambda Q: a_s*Q + 0.5*b_s*Q**2   # ∫_0^Q P_s(q)dq

# Competitive equilibrium
Qe = (a_d - a_s) / (b_d + b_s)
Pe = P_s(Qe)

# ----- Policy
policy = st.radio("Restriction:", ["None", "Price Restriction", "Quantity Restriction"])

restricted = False
Q_act, P_txn_cons, P_txn_prod = Qe, Pe, Pe    # default transaction prices (consumers/producers)

if policy == "Price Restriction":
    restricted = True
    kind = st.radio("Type:", ["Ceiling (max price)", "Floor (min price)"])
    P_bar = st.slider("Restricted Price", 0.0, 30.0, float(Pe), step=0.5)

    Qd_at = (a_d - P_bar)/b_d
    Qs_at = (P_bar - a_s)/b_s
    Q_traded = min(Qd_at, Qs_at)

    # Check binding
    if kind == "Ceiling (max price)":
        if P_bar < Pe:
            Q_act = Q_traded
            P_txn_cons = P_txn_prod = P_bar  # single market price
        else:
            restricted = False  # non-binding
    else:  # Floor
        if P_bar > Pe:
            Q_act = Q_traded
            P_txn_cons = P_txn_prod = P_bar
        else:
            restricted = False

elif policy == "Quantity Restriction":
    restricted = True
    Q_quota = st.slider("Quantity Quota", 0.0, max(Qe*1.5, 20.0), float(Qe), step=0.1)
    Q_act = Q_quota
    # In a textbook quota, consumers pay demand price, producers receive supply price; the wedge is the quota rent.
    P_txn_cons = P_d(Q_act)
    P_txn_prod = P_s(Q_act)

# ----- Welfare calculations
if not restricted:
    # Equilibrium triangles (sanity-checked)
    CS = 0.5*(a_d - Pe)*Qe
    PS = 0.5*(Pe - a_s)*Qe
    TS = CS + PS
    DWL = 0.0
    quota_rent = 0.0
else:
    # General formulas using integrals, valid for ceilings, floors, and quotas
    # Consumer Surplus: ∫_0^{Q_act} P_d(q)dq - P_cons * Q_act
    CS = A_d(Q_act) - P_txn_cons*Q_act
    # Producer Surplus: P_prod * Q_act - ∫_0^{Q_act} P_s(q)dq
    PS = P_txn_prod*Q_act - A_s(Q_act)
    # Total Surplus at Q_act (independent of who gets the wedge): ∫ (P_d - P_s) dq
    TS_act = A_d(Q_act) - A_s(Q_act)
    # Efficient TS at Qe:
    TS_e = A_d(Qe) - A_s(Qe)
    DWL = max(0.0, TS_e - TS_act)  # numerical safety
    # Quota rent (only meaningful when P_cons != P_prod)
    quota_rent = max(0.0, (P_txn_cons - P_txn_prod) * Q_act)

# ----- Plot
Qmax = max(20.0, Qe*1.5, Q_act*1.5)
Qgrid = np.linspace(0, Qmax, 400)
demand = P_d(Qgrid)
supply = P_s(Qgrid)

fig, ax = plt.subplots()
ax.plot(Qgrid, demand, color="blue", label="Demand")
ax.plot(Qgrid, supply, color="orange", label="Supply")

# Shade CS, PS using correct baselines
if not restricted:
    ax.fill_between(Qgrid[Qgrid <= Qe], Pe, P_d(Qgrid[Qgrid <= Qe]),
                    color="blue", alpha=0.25, label="CS")
    ax.fill_between(Qgrid[Qgrid <= Qe], P_s(Qgrid[Qgrid <= Qe]), Pe,
                    color="orange", alpha=0.25, label="PS")
else:
    # CS relative to consumers' transaction price
    ax.fill_between(Qgrid[Qgrid <= Q_act], P_txn_cons, P_d(Qgrid[Qgrid <= Q_act]),
                    color="blue", alpha=0.25, label="CS")
    # PS relative to producers' transaction price
    ax.fill_between(Qgrid[Qgrid <= Q_act], P_s(Qgrid[Qgrid <= Q_act]), P_txn_prod,
                    color="orange", alpha=0.25, label="PS")
    # Quota rent rectangle (if any)
    if P_txn_cons > P_txn_prod:
        ax.fill_between([0, Q_act], P_txn_prod, P_txn_cons, step="post",
                        color="green", alpha=0.18, label="Quota Rent")
    # DWL triangle between curves from Q_act to Qe
    QL = min(Q_act, Qe); QH = max(Q_act, Qe)
    mask = (Qgrid >= QL) & (Qgrid <= QH)
    if np.any(mask):
        upper = np.maximum(P_d(Qgrid[mask]), P_s(Qgrid[mask]))
        lower = np.minimum(P_d(Qgrid[mask]), P_s(Qgrid[mask]))
        ax.fill_between(Qgrid[mask], lower, upper, color="gray", alpha=0.18, label="DWL")

# Points
ax.scatter(Qe, Pe, color="red", zorder=5, label="Equilibrium")
ax.scatter(Q_act, P_txn_cons, color="purple", zorder=5, label="Actual (consumers)")
if abs(P_txn_cons - P_txn_prod) > 1e-9:
    ax.scatter(Q_act, P_txn_prod, color="brown", zorder=5, label="Actual (producers)")

ax.set_xlabel("Quantity (Q)")
ax.set_ylabel("Price (P)")
ax.set_xlim(left=0)
ax.set_ylim(bottom=0)
ax.legend(loc="best", ncol=2, fontsize=8)
ax.grid(alpha=0.3)
st.pyplot(fig)

# ----- Readout
st.markdown(f"""
**Equilibrium:** P* = {Pe:.2f}, Q* = {Qe:.2f}  
**Actual outcome:** P_c = {P_txn_cons:.2f}, P_p = {P_txn_prod:.2f}, Q = {Q_act:.2f}

**Consumer Surplus:** {CS:.2f}  
**Producer Surplus:** {PS:.2f}  
**Quota Rent (if applicable):** {quota_rent:.2f}  
**Total Surplus (actual):** {A_d(Q_act) - A_s(Q_act):.2f}  
**Deadweight Loss:** {DWL:.2f}
""")