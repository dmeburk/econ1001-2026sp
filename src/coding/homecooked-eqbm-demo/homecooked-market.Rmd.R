---
  title: "Homecooked Market Demo"
output:
  html_document:
  self_contained: true
---
  
```{r, message=FALSE, warning=FALSE}
library(tidyverse)
library(plotly)

source("load-homecooked-data.R")

# --- paste ALL your existing code here unchanged ---
``` 

homecooking <- load_homecooked_data(target_n = 225)

stopifnot(all(homecooking$role %in% c("demander", "supplier")))

# ----------------------------
# HANDLE DUPLICATE PRICES
# (small offsets so points don’t overlap)
# ----------------------------

homecooking <- homecooking %>%
  group_by(price) %>%
  mutate(price = price + (row_number() - 1) * 0.01) %>%
  ungroup()

# ----------------------------
# SPLIT BY ROLE
# ----------------------------

demanders <- homecooking %>%
  filter(role == "demander") %>%
  select(name, price)

suppliers <- homecooking %>%
  filter(role == "supplier") %>%
  select(name, price)


# ----------------------------
# BUILD EMPIRICAL CURVES
# ----------------------------

build_curve <- function(df, side = c("Demand", "Supply")) {
  side <- match.arg(side)
  
  if (side == "Demand") {
    df %>%
      arrange(desc(price)) %>%      # highest WTP first
      mutate(quantity = row_number())
  } else {
    df %>%
      arrange(price) %>%            # lowest WTA first
      mutate(quantity = row_number())
  }
}

D <- build_curve(demanders, "Demand")
S <- build_curve(suppliers, "Supply")

# ----------------------------
# PLOT
# ----------------------------

## Figure 1: Market
fig_market <- plot_ly(
  D,
  x = ~quantity,
  y = ~price,
  type = "scatter",
  mode = "lines+markers",
  line = list(shape = "hv", width = 2),
  name = "Demand",
  text = ~paste(
    "Q =", quantity,
    "<br>Buyer:", name,
    "<br>WTP:", round(price, 2)
  ),
  hoverinfo = "text"
) %>%
  add_trace(
    data = S,
    x = ~quantity,
    y = ~price,
    type = "scatter",
    mode = "lines+markers",
    line = list(shape = "hv", width = 2),
    name = "Supply",
    text = ~paste(
      "Q =", quantity,
      "<br>Seller:", name,
      "<br>WTA:", round(price, 2)
    ),
    hoverinfo = "text"
  ) %>%
  layout(
    title = list(
      text = "Homecooked Meal Market",
      y = 0.95   # push title down slightly
    ),
    xaxis = list(title = "Quantity"),
    yaxis = list(title = "Price")
  )



# ============================================================
# FIGURE 2: Market at a Given Price (with Rationing & Surplus)
# ============================================================

make_price_fig <- function(PRICE_TO_STUDY) {
  #PRICE_TO_STUDY <- 20.02
  
  # ------------------------------------------------------------
  # 1. Order agents correctly and index quantity
  # ------------------------------------------------------------
  
  D2 <- D %>%
    arrange(desc(price)) %>%           # highest WTP first
    mutate(quantity = row_number())
  
  S2 <- S %>%
    arrange(price) %>%                 # lowest WTA first
    mutate(quantity = row_number())
  
  # ------------------------------------------------------------
  # 2. Determine how many actually trade (short side)
  # ------------------------------------------------------------
  
  Q_d <- sum(D2$price >= PRICE_TO_STUDY)
  Q_s <- sum(S2$price <= PRICE_TO_STUDY)
  Q_traded <- min(Q_d, Q_s)
  
  # ------------------------------------------------------------
  # 3. Traders only (THIS is the key)
  # ------------------------------------------------------------
  
  buyers_in  <- D2[1:Q_traded, ]
  sellers_in <- S2[1:Q_traded, ]
  
  # ------------------------------------------------------------
  # 3.5 Compute surplus
  # ------------------------------------------------------------
  
  consumer_surplus <- sum(buyers_in$price - PRICE_TO_STUDY)
  producer_surplus <- sum(PRICE_TO_STUDY - sellers_in$price)
  total_surplus    <- consumer_surplus + producer_surplus
  
  # ------------------------------------------------------------
  # 4. Build figure
  # ------------------------------------------------------------
  
  fig_price <- plot_ly() %>%
    # Demand curve
    add_trace(
      data = D2,
      x = ~quantity,
      y = ~price,
      type = "scatter",
      mode = "lines+markers",
      line = list(shape = "hv"),
      name = "Demand",
      text = ~paste("Buyer:", name, "<br>WTP:", price),
      hoverinfo = "text"
    ) %>%
    # Supply curve
    add_trace(
      data = S2,
      x = ~quantity,
      y = ~price,
      type = "scatter",
      mode = "lines+markers",
      line = list(shape = "hv"),
      name = "Supply",
      text = ~paste("Seller:", name, "<br>WTA:", price),
      hoverinfo = "text"
    ) %>%
    # Price line
    add_segments(
      x = 0,
      xend = max(c(D2$quantity, S2$quantity)),
      y = PRICE_TO_STUDY,
      yend = PRICE_TO_STUDY,
      line = list(dash = "dash"),
      name = "Price",
      hoverinfo = "skip",
      text = NULL
    ) %>%
    # Consumer surplus bars (buyers)
    add_segments(
      data = buyers_in,
      x = ~quantity,
      xend = ~quantity,
      y = PRICE_TO_STUDY,
      yend = ~price,
      line = list(color = "lightblue", width = 8),
      name = "Consumer surplus",
      hoverinfo = "skip",
      text = NULL
    ) %>%
    # Producer surplus bars (sellers)
    add_segments(
      data = sellers_in,
      x = ~quantity,
      xend = ~quantity,
      y = ~price,
      yend = PRICE_TO_STUDY,
      line = list(color = "lightsalmon", width = 8),
      name = "Producer surplus",
      hoverinfo = "skip",
      text = NULL
    ) %>%
    layout(
      title = paste0(
        "Market at Price = ", PRICE_TO_STUDY,
        "  (Q traded = ", Q_traded, ")"
      ),
      xaxis = list(title = "Quantity"),
      yaxis = list(title = "Price")
    )
  
  
  fig_price <- fig_price %>%
    layout(
      title = list(
        text = paste0(
          "Market at Price = ", PRICE_TO_STUDY,
          " (Q traded = ", Q_traded, ")"
        ),
        y = 0.95   # move title down slightly
      ),
      margin = list(t = 80),  # extra space for title + icons
      xaxis = list(title = "Quantity"),
      yaxis = list(title = "Price")
    )
  
  fig_price <- fig_price %>%
    layout(
      annotations = list(
        list(
          x = max(c(D$quantity, S$quantity)) * 0.7,
          y = max(c(D$price, S$price)),
          align = "left",
          text = paste0(
            "<b>Surplus at Price = ", PRICE_TO_STUDY, "</b>",
            "<br>Consumer surplus: ", round(consumer_surplus, 2),
            "<br>Producer surplus: ", round(producer_surplus, 2),
            "<br><b>Total surplus: ", round(total_surplus, 2), "</b>"
          ),
          showarrow = FALSE,
          bgcolor = "rgba(255,255,255,0.8)",
          bordercolor = "black",
          borderwidth = 1
        )
      )
    )
  
  fig_price
}

fig_eq   <- make_price_fig(20.02)
fig_low  <- make_price_fig(15)
fig_high <- make_price_fig(25)


###
# Figures to Show Class
####
fig_market
fig_low
fig_high
fig_eq  
