price <- 1:9

df <- data.frame(
  P = price,
  Q_Prof = c(20,18,16,14,12,10,8,6,4),
  Q_SadProf = c(15,13,11,9,7,5,3,1,NA),
  Q_RichProf = c(25,23,21,19,17,15,13,11,9)
)

plot(df$Q_Prof, df$P,
     type = "l",
     lwd = 2,
     xlim = c(0, 26),
     ylim = c(1, 9),
     xlab = "Quantity",
     ylab = "Price",
     main = "Demand Curves")
legend("topright",
       legend = c("Prof"),
       lwd = 2,
       lty = c(1),
       bty = "n")

plot(df$Q_Prof, df$P,
     type = "l",
     lwd = 2,
     xlim = c(0, 26),
     ylim = c(1, 9),
     xlab = "Quantity",
     ylab = "Price",
     main = "Demand Curves")
lines(df$Q_SadProf, df$P, lwd = 2, lty = 2)
legend("topright",
       legend = c("Prof", "Sad Prof"),
       lwd = 2,
       lty = c(1, 2),
       bty = "n")

plot(df$Q_Prof, df$P,
     type = "l",
     lwd = 2,
     xlim = c(0, 26),
     ylim = c(1, 9),
     xlab = "Quantity",
     ylab = "Price",
     main = "Demand Curves")
lines(df$Q_SadProf, df$P, lwd = 2, lty = 2)
lines(df$Q_RichProf, df$P, lwd = 2, lty = 3)
legend("topright",
       legend = c("Prof", "Sad Prof", "Rich Prof"),
       lwd = 2,
       lty = c(1, 2, 3),
       bty = "n")

