## Fiscal Year Churn Tracker 
rm(list=ls())

library(anytime)
## First Friday of the FY
ff_fy <- as.character("20211001")

## Update Start Date, the Saturday preeceding last weeks Friday 
sd <- as.character("20220430")
## End Date, last weeks Friday
ed <- as.character("20220506")
## 6 month start date, last weeks Friday 6 months preceeding 
mm <- as.character("20211006")

ff <- anydate(ff_fy)
dt <- anydate(ed)
txt_ff <- format(ff, "%d%b%Y")
txt_dt <- format(dt, "%d%b%Y")

## pull in the utility functions
source("O:/ORSA_Workflow/24 Attrition/Weekly/FY_churn_track/attrUtils.R")

w <- lubridate::isoweek(dt)
fy_w <- setFYweek(w)

## Check the run date
chkRundate(sd)
chkRundate(ed)
chkRundate(mm)

## Call functions and run the SQL statements
## Load Package to clean names of an object
library(tidyverse)
library(janitor)

## gains
wg <- weeklyGain(sd, ed) %>% clean_names() %>% arrange(mpc, cnt) %>% mutate(count = cnt) %>% select(-cnt)
mg <- sixMoGain(mm, ed) %>% clean_names() %>% arrange(mpc, gain_rsn) %>% mutate(count = cnt, avg_gain = count/26) %>% select(-cnt)
## losses
wl <- weeklyLoss(sd, ed) %>% clean_names() %>% arrange(mpc, cnt) %>% mutate(count = cnt) %>% select(-cnt)
ml <- sixMoLoss(mm, ed) %>% clean_names() %>% arrange(mpc, loss_rsn) %>% mutate(count = cnt, avg_loss = cnt/26) %>% select(-cnt)
## summary
sl <- wkSelresL(sd, ed) %>% clean_names()
sg <- wkSelresG(sd, ed) %>% clean_names()
ss <- wkSelresStr(sd, ed) %>% clean_names()

## Create the historic gains
## weekly totals
x_wg <- mg %>% inner_join(wg, by= c("mpc" = "mpc", "gain_rsn" = "gain_rsn")) %>% 
  mutate(rcc = rcc.x,
         reason_desc = reason_desc.x,
         count = count.y,
         six_mo_avg = round(avg_gain,0),
         delta = count.y - six_mo_avg,
         six_mo_num = count.x,
         wkly_pctovr6mo = round(((count.y/count.x)*100),2)) %>% 
  select(mpc, rcc, gain_rsn, reason_desc, count, six_mo_avg, delta, six_mo_num, wkly_pctovr6mo) 

## Create the historic losses
## weekly totals
x_wl <- ml %>% inner_join(wl, by= c("mpc" = "mpc", "loss_rsn" = "loss_rsn")) %>% 
  mutate(rcc = rcc.x,
         reason_desc = reason_desc.x,
         count = count.y,
         six_mo_avg = round(avg_loss,0),
         delta = count.y - six_mo_avg,
         six_mo_num = count.x,
         wkly_pctovr6mo = round(((count.y/count.x)*100),2)) %>% 
  select(mpc, rcc, loss_rsn, reason_desc, count, six_mo_avg, delta, six_mo_num, wkly_pctovr6mo) 

## banner gain numbers
g_ewt <- x_wg %>% filter(x_wg$mpc=="E") %>% summarise(sum(count)) %>% as.double()
g_owt <- x_wg %>% filter(x_wg$mpc=="O") %>% summarise(sum(count)) %>% as.double()
g_wwt <- x_wg %>% filter(x_wg$mpc=="W") %>% summarise(sum(count)) %>% as.double()
g_two = g_owt + g_wwt
g_wk_tot <- x_wg %>% summarise(sum(count)) %>% as.double()

g_emt <- mg %>% filter(mg$mpc=="E") %>% summarise(sum(count)) %>% as.double()
g_emt_avg <- round(g_emt/26,2) %>% as.double()
g_omt <- mg %>% filter(mg$mpc=="O") %>% summarise(sum(count)) %>% as.double()
g_omt_avg <- round(g_omt/26,2) %>% as.double()
g_wmt <- mg %>% filter(mg$mpc=="W") %>% summarise(sum(count)) %>% as.double()
g_wmt_avg <- round(g_wmt/26,2) %>% as.double()
g_tmo = g_wmt_avg + g_omt_avg
g_avg_tot = g_wmt_avg + g_omt_avg + g_emt_avg

## banner loss numbers
l_ewt <- x_wl %>% filter(x_wl$mpc=="E") %>% summarize(sum(count)) %>% as.double()
l_owt <- x_wl %>% filter(x_wl$mpc=="O") %>% summarise(sum(count)) %>% as.double()
l_wwt <- x_wl %>% filter(x_wl$mpc=="W") %>% summarise(sum(count)) %>% as.double()
l_two = l_owt + l_wwt
l_wk_tot <- x_wl %>% summarise(sum(count)) %>% as.double()

l_emt <- ml %>% filter(ml$mpc=="E") %>% summarise(sum(count)) %>% as.double()
l_emt_avg <- round(l_emt/26,2) %>% as.double()
l_omt <- ml %>% filter(ml$mpc=="O") %>% summarise(sum(count)) %>% as.double()
l_omt_avg <- round(l_omt/26,2) %>% as.double()
l_wmt <- ml %>% filter(ml$mpc=="W") %>% summarise(sum(count)) %>% as.double()
l_wmt_avg <- round(l_wmt/26,2) %>% as.double()
l_tmo = l_wmt_avg + l_omt_avg
l_avg_tot = l_wmt_avg + l_omt_avg + l_emt_avg

lbl_w = "Weekly"
lbl_m = "6 Month Average"

g_lbl_e = "Total Gains - Enlisted"
g_lbl_g = "Total Gains - Officer"
g_lbl_w = "Total Gains - Warrant"

l_lbl_e = "Total Losses - Enlisted"
l_lbl_g = "Total Losses - Officer"
l_lbl_w = "Total Losses - Warrant"

## summary excel file

asgn_str <- ss %>% select(selres_strength) %>% max()
net_loss <- sl %>% select(selres_loss) %>% max()
net_gain <- sg %>% select(selres_gain) %>% max()

churn <- (net_gain - net_loss)

wks_left <- (52 - fy_w)

## Write the DF to an excel file
library(openxlsx)

wb1 <- loadWorkbook("historic_gains_FY22.xlsx")
wb2 <- loadWorkbook("historic_losses_FY22.xlsx")
wb3 <- loadWorkbook("Churn_track_FY22.xlsx")

worksheetOrder(wb1)
z <- worksheetOrder(wb1)

# q <- worksheetOrder(wb2)
# worksheetOrder(wb2) <- rev(q)

addWorksheet(wb1, txt_dt)
addWorksheet(wb2, txt_dt)

## create workbook style
centerStyle1 <- createStyle(fontSize = 10, fontName = "Arial", fgFill = "#FFFF00",
                            halign = "center", valign = "center", wrapText = T)

bodyStyle2 <- createStyle(fontSize = 8, fontName = "Arial",
                           halign = "center", valign = "center")

bodyStyle <- createStyle(fontSize = 8, fontName = "Arial",
                         halign = "center", valign = "bottom",
                         border = c("top", "bottom", "left", "right"), borderColour = "#000000")

headerStyle <- createStyle(fontSize = 8, fontName = "Arial", fontColour = "#FF6600", fgFill ="#EBECF0", textDecoration = "bold",
                           halign = "center", valign = "center", 
                           border = c("top", "bottom", "left", "right"), borderColour = "#000000")

## write gain weekly data 
writeData(wb1, txt_dt, lbl_w, startCol = 1, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, centerStyle1, cols = 1, rows = 1)

writeData(wb1, txt_dt, "E", startCol = 3, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, "O", startCol = 3, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, "W", startCol = 3, startRow = 3, rowNames = F, borders = "all", borderColour = "black")

writeData(wb1, txt_dt, g_lbl_e, startCol = 4, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_lbl_g, startCol = 4, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_lbl_w, startCol = 4, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 4, rows = 1:3)

writeData(wb1, txt_dt, g_ewt, startCol = 5, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_owt, startCol = 5, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_wwt, startCol = 5, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 5, rows = 1:3)

writeData(wb1, txt_dt, g_two, startCol = 6, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 6, rows = 2:3)

writeData(wb1, txt_dt, "Total Gain", startCol = 7, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_wk_tot, startCol = 7, startRow = 2, rowNames = F, borders = "all", borderColour = "black")

writeData(wb1, txt_dt, x_wg, startCol = 1, startRow = 5, rowNames = F, borders = "all", borderColour = "black")

addStyle(wb1, txt_dt, bodyStyle, cols = 1:9, rows = 5:200, gridExpand = T)

setColWidths(wb1, txt_dt, cols = 1:2, widths = 4.5)
setColWidths(wb1, txt_dt, cols = 3:9, widths = "auto")

mergeCells(wb1, txt_dt, cols = 6, rows = 2:3)
mergeCells(wb1, txt_dt, cols = 1:2, rows = 1:4)

## write gain monthly data 

writeData(wb1, txt_dt, lbl_m, startCol = 11, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, centerStyle1, cols = 11, rows = 1)

writeData(wb1, txt_dt, "E", startCol = 13, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, "O", startCol = 13, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, "W", startCol = 13, startRow = 3, rowNames = F, borders = "all", borderColour = "black")

writeData(wb1, txt_dt, g_lbl_e, startCol = 14, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_lbl_g, startCol = 14, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_lbl_w, startCol = 14, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 14, rows = 1:3)

writeData(wb1, txt_dt, g_emt, startCol = 15, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_omt, startCol = 15, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_wmt, startCol = 15, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 15, rows = 1:3)

writeData(wb1, txt_dt, g_emt_avg, startCol = 16, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_omt_avg, startCol = 16, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_wmt_avg, startCol = 16, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 16, rows = 1:3)

writeData(wb1, txt_dt, g_tmo, startCol = 17, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb1, txt_dt, headerStyle, cols = 17, rows = 2:3)

writeData(wb1, txt_dt, "Avg Gain", startCol = 18, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb1, txt_dt, g_avg_tot, startCol = 18, startRow = 2, rowNames = F, borders = "all", borderColour = "black")

writeData(wb1, txt_dt, mg, startCol = 11, startRow = 5, rowNames = F, borders = "all", borderColour = "black")

addStyle(wb1, txt_dt, bodyStyle, cols = 11:16, rows = 5:200, gridExpand = T)

setColWidths(wb1, txt_dt, cols = 11:12, widths = 4.5)
setColWidths(wb1, txt_dt, cols = 13:16, widths = "auto")

mergeCells(wb1, txt_dt, cols = 17, rows = 2:3)
mergeCells(wb1, txt_dt, cols = 11:12, rows = 1:4)

## write losses weekly data 
writeData(wb2, txt_dt, lbl_w, startCol = 1, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, centerStyle1, cols = 1, rows = 1)

writeData(wb2, txt_dt, "E", startCol = 3, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, "O", startCol = 3, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, "W", startCol = 3, startRow = 3, rowNames = F, borders = "all", borderColour = "black")

writeData(wb2, txt_dt, l_lbl_e, startCol = 4, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_lbl_g, startCol = 4, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_lbl_w, startCol = 4, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 4, rows = 1:3)

writeData(wb2, txt_dt, l_ewt, startCol = 5, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_owt, startCol = 5, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_wwt, startCol = 5, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 5, rows = 1:3)

writeData(wb2, txt_dt, l_two, startCol = 6, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 6, rows = 2:3)

writeData(wb2, txt_dt, "Total Gain", startCol = 7, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_wk_tot, startCol = 7, startRow = 2, rowNames = F, borders = "all", borderColour = "black")

writeData(wb2, txt_dt, x_wl, startCol = 1, startRow = 5, rowNames = F, borders = "all", borderColour = "black")

addStyle(wb2, txt_dt, bodyStyle, cols = 1:9, rows = 5:200, gridExpand = T)

setColWidths(wb2, txt_dt, cols = 1:2, widths = 4.5)
setColWidths(wb2, txt_dt, cols = 3:9, widths = "auto")

mergeCells(wb2, txt_dt, cols = 6, rows = 2:3)
mergeCells(wb2, txt_dt, cols = 1:2, rows = 1:4)

## write losses monthly data 

writeData(wb2, txt_dt, lbl_m, startCol = 11, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, centerStyle1, cols = 11, rows = 1)

writeData(wb2, txt_dt, "E", startCol = 13, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, "O", startCol = 13, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, "W", startCol = 13, startRow = 3, rowNames = F, borders = "all", borderColour = "black")

writeData(wb2, txt_dt, l_lbl_e, startCol = 14, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_lbl_g, startCol = 14, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_lbl_w, startCol = 14, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 14, rows = 1:3, gridExpand = T)

writeData(wb2, txt_dt, l_emt, startCol = 15, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_omt, startCol = 15, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_wmt, startCol = 15, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 15, rows = 1:3, gridExpand = T)

writeData(wb2, txt_dt, l_emt_avg, startCol = 16, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_omt_avg, startCol = 16, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_wmt_avg, startCol = 16, startRow = 3, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 16, rows = 1:3)

writeData(wb2, txt_dt, l_tmo, startCol = 17, startRow = 2, rowNames = F, borders = "all", borderColour = "black")
addStyle(wb2, txt_dt, headerStyle, cols = 17, rows = 2:3, gridExpand = T)

writeData(wb2, txt_dt, "Avg Gain", startCol = 18, startRow = 1, rowNames = F, borders = "all", borderColour = "black")
writeData(wb2, txt_dt, l_avg_tot, startCol = 18, startRow = 2, rowNames = F, borders = "all", borderColour = "black")

writeData(wb2, txt_dt, ml, startCol = 11, startRow = 5, rowNames = F, borders = "all", borderColour = "black")

addStyle(wb2, txt_dt, bodyStyle, cols = 11:16, rows = 5:200, gridExpand = T)

setColWidths(wb2, txt_dt, cols = 11:12, widths = 4.5)
setColWidths(wb2, txt_dt, cols = 13:16, widths = "auto")

mergeCells(wb2, txt_dt, cols = 17, rows = 2:3)
mergeCells(wb2, txt_dt, cols = 11:12, rows = 1:4)

# gains tracking 
sc <- fy_w + 5

ea <- x_wg %>% filter(mpc=='E' & gain_rsn=='AA') %>% select(count) %>% as.double()
ef <- x_wg %>% filter(mpc=='E' & gain_rsn=='FE') %>% select(count) %>% as.double()
eh <- x_wg %>% filter(mpc=='E' & gain_rsn=='HV') %>% select(count) %>% as.double()
ek <- x_wg %>% filter(mpc=='E' & gain_rsn=='BK') %>% select(count) %>% as.double()
eb <- x_wg %>% filter(mpc=='E' & gain_rsn=='BF') %>% select(count) %>% as.double()
el <- x_wg %>% filter(mpc=='E' & gain_rsn=='AL') %>% select(count) %>% as.double()
of <- x_wg %>% filter(mpc=='O' & gain_rsn=='FE') %>% select(count) %>% as.double()
ol <- x_wg %>% filter(mpc=='O' & gain_rsn=='AL') %>% select(count) %>% as.double()
ok <- x_wg %>% filter(mpc=='O' & gain_rsn=='BK') %>% select(count) %>% as.double()
wa <- x_wg %>% filter(mpc=='W' & gain_rsn=='AL') %>% select(count) %>% as.double()
wf <- x_wg %>% filter(mpc=='W' & gain_rsn=='FE') %>% select(count) %>% as.double()

writeData(wb1, "Tracking", txt_dt, startCol = sc, startRow = 1, rowNames = F)
writeData(wb1, "Tracking", ea, startCol = sc, startRow = 2, rowNames = F)
writeData(wb1, "Tracking", ef, startCol = sc, startRow = 3, rowNames = F)
writeData(wb1, "Tracking", eh, startCol = sc, startRow = 4, rowNames = F)
writeData(wb1, "Tracking", ek, startCol = sc, startRow = 5, rowNames = F)
writeData(wb1, "Tracking", eb, startCol = sc, startRow = 6, rowNames = F)
writeData(wb1, "Tracking", el, startCol = sc, startRow = 7, rowNames = F)
writeData(wb1, "Tracking", of, startCol = sc, startRow = 8, rowNames = F)
writeData(wb1, "Tracking", ol, startCol = sc, startRow = 9, rowNames = F)
writeData(wb1, "Tracking", ok, startCol = sc, startRow = 10, rowNames = F)
writeData(wb1, "Tracking", wa, startCol = sc, startRow = 11, rowNames = F)
writeData(wb1, "Tracking", wf, startCol = sc, startRow = 12, rowNames = F)

writeData(wb1, "Tracking", g_wk_tot, startCol = sc, startRow = 18, rowNames = F)
writeData(wb1, "Tracking", g_ewt, startCol = sc, startRow = 19, rowNames = F)
writeData(wb1, "Tracking", g_wwt, startCol = sc, startRow = 20, rowNames = F)
writeData(wb1, "Tracking", g_owt, startCol = sc, startRow = 21, rowNames = F)
writeData(wb1, "Tracking", g_tmo, startCol = sc, startRow = 22, rowNames = F)
writeData(wb1, "Tracking", round(g_emt_avg,0), startCol = sc, startRow = 23, rowNames = F)

writeData(wb1, "Tracking", round(g_avg_tot,0), startCol = sc, startRow = 43, rowNames = F)
addStyle(wb1, "Tracking", bodyStyle2, cols = 5:sc, rows = 1:45, gridExpand = T)

# losses tracking
c <- fy_w + 5

bf <- x_wl %>% filter(mpc=='E' & loss_rsn=='BF') %>% select(count) %>% as.double()
eg <- x_wl %>% filter(mpc=='E' & loss_rsn=='EG') %>% select(count) %>% as.double()
ga <- x_wl %>% filter(mpc=='E' & loss_rsn=='GA') %>% select(count) %>% as.double()
fe <- x_wl %>% filter(mpc=='E' & loss_rsn=='FE') %>% select(count) %>% as.double()
hv <- x_wl %>% filter(mpc=='E' & loss_rsn=='HV') %>% select(count) %>% as.double()
gl <- x_wl %>% filter(mpc=='E' & loss_rsn=='GL') %>% select(count) %>% as.double()
dx <- x_wl %>% filter(mpc=='E' & loss_rsn=='DX') %>% select(count) %>% as.double()
ca <- x_wl %>% filter(mpc=='E' & loss_rsn=='CA') %>% select(count) %>% as.double()
ja <- x_wl %>% filter(mpc=='E' & loss_rsn=='JA') %>% select(count) %>% as.double()
dw <- x_wl %>% filter(mpc=='E' & loss_rsn=='DW') %>% select(count) %>% as.double()
sd <- x_wl %>% filter(mpc=='E' & loss_rsn=='SD') %>% select(count) %>% as.double()
fj <- x_wl %>% filter(mpc=='E' & loss_rsn=='FJ') %>% select(count) %>% as.double()
by <- x_wl %>% filter(mpc=='E' & loss_rsn=='BY') %>% select(count) %>% as.double()
kk <- x_wl %>% filter(mpc=='E' & loss_rsn=='KK') %>% select(count) %>% as.double()
tn <- x_wl %>% filter(mpc=='E' & loss_rsn=='TN') %>% select(count) %>% as.double()
hj <- x_wl %>% filter(mpc=='E' & loss_rsn=='HJ') %>% select(count) %>% as.double()
ft <- x_wl %>% filter(mpc=='E' & loss_rsn=='FT') %>% select(count) %>% as.double()
ta <- x_wl %>% filter(mpc=='E' & loss_rsn=='TA') %>% select(count) %>% as.double()
fk <- x_wl %>% filter(mpc=='E' & loss_rsn=='FK') %>% select(count) %>% as.double()
dz <- x_wl %>% filter(mpc=='E' & loss_rsn=='DZ') %>% select(count) %>% as.double()
bb <- x_wl %>% filter(mpc=='E' & loss_rsn=='BB') %>% select(count) %>% as.double()

bf_rd <- ml %>% filter(mpc=='E' & loss_rsn=='BF') %>% select(avg_loss) %>% as.double()

writeData(wb2, "Tracking", txt_dt, startCol = sc, startRow = 1, rowNames = F)
writeData(wb2, "Tracking", bf, startCol = c, startRow = 2, rowNames = F)
writeData(wb2, "Tracking", eg, startCol = c, startRow = 3, rowNames = F)
writeData(wb2, "Tracking", ga, startCol = c, startRow = 4, rowNames = F)
writeData(wb2, "Tracking", fe, startCol = c, startRow = 5, rowNames = F)
writeData(wb2, "Tracking", hv, startCol = c, startRow = 6, rowNames = F)
writeData(wb2, "Tracking", gl, startCol = c, startRow = 7, rowNames = F)
writeData(wb2, "Tracking", dx, startCol = c, startRow = 8, rowNames = F)
writeData(wb2, "Tracking", ca, startCol = c, startRow = 9, rowNames = F)
writeData(wb2, "Tracking", ja, startCol = c, startRow = 10, rowNames = F)
writeData(wb2, "Tracking", dw, startCol = c, startRow = 11, rowNames = F)
writeData(wb2, "Tracking", sd, startCol = c, startRow = 12, rowNames = F)
writeData(wb2, "Tracking", fj, startCol = c, startRow = 13, rowNames = F)
writeData(wb2, "Tracking", by, startCol = c, startRow = 14, rowNames = F)
writeData(wb2, "Tracking", kk, startCol = c, startRow = 15, rowNames = F)
writeData(wb2, "Tracking", tn, startCol = c, startRow = 16, rowNames = F)
writeData(wb2, "Tracking", hj, startCol = c, startRow = 17, rowNames = F)
writeData(wb2, "Tracking", ft, startCol = c, startRow = 18, rowNames = F)
writeData(wb2, "Tracking", ta, startCol = c, startRow = 19, rowNames = F)
writeData(wb2, "Tracking", fk, startCol = c, startRow = 20, rowNames = F)
writeData(wb2, "Tracking", dz, startCol = c, startRow = 21, rowNames = F)
writeData(wb2, "Tracking", bb, startCol = c, startRow = 22, rowNames = F)

writeData(wb2, "Tracking", l_ewt, startCol = c, startRow = 26, rowNames = F)
writeData(wb2, "Tracking", round(l_emt_avg,0), startCol = c, startRow = 27, rowNames = F)
writeData(wb2, "Tracking", round(bf_rd,0), startCol = c, startRow = 28, rowNames = F)

writeData(wb2, "Tracking", l_two, startCol = c, startRow = 41, rowNames = F)
writeData(wb2, "Tracking", round(l_tmo,0), startCol = c, startRow = 42, rowNames = F)
writeData(wb2, "Tracking", round(l_wk_tot,0), startCol = c, startRow = 43, rowNames = F)
writeData(wb2, "Tracking", round(l_avg_tot,0), startCol = c, startRow = 44, rowNames = F)
addStyle(wb2, "Tracking", bodyStyle2, cols = 5:sc, rows = 1:47, gridExpand = T)

## SELRES churn summary
## write summary data
sr <- fy_w + 2

# projES <- paste0("=E",sr,"+Q3")
# wklyneteso <- paste0("=(N1-E",sr,")/(53-D",sr,")")
# wklynetadj <- paste0("=ROUND((N2-E",sr,")/(53-D",sr,"),0)")
# wklynetflr <- paste0("=ROUND((N3-E",sr,")/(53-D",sr,"),0)")
# gainlossprv <- paste0("=J",sr)

writeData(wb3, "FY22", asgn_str, startCol = 5, startRow = sr, rowNames = F, borders = "all", borderColour = "black")
writeData(wb3, "FY22", net_loss, startCol = 6, startRow = sr, rowNames = F, borders = "all", borderColour = "black")
writeData(wb3, "FY22", net_gain, startCol = 8, startRow = sr, rowNames = F, borders = "all", borderColour = "black")
#writeData(wb3, "FY22", churn, startCol = 10, startRow = sr, rowNames = F, borders = "all", borderColour = "black")
# addStyle(wb3, "FY22", bodyStyle, cols = 5:11, rows = 2:53, gridExpand = T)
# writeData(wb3, "FY22", wks_left, startCol = 17, startRow = 2, rowNames = F, borders = "all")
# addStyle(wb3, "FY22", bodyStyle, cols = 17, rows = 2, gridExpand = T)
# writeData(wb3, "FY22", projES, startCol = 17, startRow = 4, rowNames = F, borders = "all")
# writeData(wb3, "FY22", wklyneteso, startCol = 19, startRow = 1, rowNames = F, borders = "all")
# writeData(wb3, "FY22", wklynetadj, startCol = 19, startRow = 2, rowNames = F, borders = "all")
# writeData(wb3, "FY22", wklynetflr, startCol = 19, startRow = 3, rowNames = F, borders = "all")
# writeData(wb3, "FY22", gainlossprv, startCol = 19, startRow = 4, rowNames = F, borders = "all")

## save historic losses xlsx file
saveWorkbook(wb1, "historic_gains_FY22.xlsx", overwrite = T)
saveWorkbook(wb2, "historic_losses_FY22.xlsx", overwrite = T)
saveWorkbook(wb3, "Churn_track_FY22.xlsx", overwrite = T)

rm(list=ls())

