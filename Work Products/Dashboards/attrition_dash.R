######################################################################
## master attrition dashboard
## date: 11 Jan 2022
## MAJ Androff
######################################################################

library(anytime)
library(openxlsx)
library(data.table)
library(anytime)

## create as of date
dt <- format(anydate(as.character(Sys.time())), "%d%b%Y")
txt_dt <- paste0("As of ",dt)

## call functions to pull the FYTD losses, gains and strength
source("sql.R")

## pass in your Fiscal Year and month variable 4 characters in length
fy <- as.character(2016:2022)
mo <- as.character(c("1001","1101","1201","0101","0201","0301","0401","0501","0601","0701", "0801", "0901"))

## pulls in attrition data as a data table
## stength: roll up of losses and gains by CMD/MSC
gla_cmd <- list(gain_loss_asg_cmd(fy[6],mo[3]))

cmd_loss_tot <- gla_cmd[[1]][[1]]
selres_loss_tot <- gla_cmd[[1]][[2]]
cmd_gain_tot <- gla_cmd[[1]][[3]]
mpc_gain_tot <- gla_cmd[[1]][[4]]
cmd_asg_tot <- gla_cmd[[1]][[5]]
selres_tot <- gla_cmd[[1]][[6]]

## Gains
gains <- list(gains_onestop(fy[6],mo[3]))

g_all <- gains[[1]][[1]]
g_mpc <- gains[[1]][[2]]
g_cur <- gains[[1]][[3]]
g_grd <- gains[[1]][[4]]
g_rcc <- gains[[1]][[5]]

## Losses
losses <- list(losses_onestop(fy[6],mo[3]))

l_all <- losses[[1]][[1]]
l_rsn <- losses[[1]][[2]]
l_cur <- losses[[1]][[3]]
l_grd <- losses[[1]][[4]]
l_mos <- losses[[1]][[5]]

## Create a new workbook and add a worksheet
wb <- createWorkbook()

## CMD/MSC gains/losses by with totals
addWorksheet(wb, sheetName = "dash")
addWorksheet(wb, sheetName = "gainsByCMD")
addWorksheet(wb, sheetName = "lossesByCMD")
addWorksheet(wb, sheetName = "assignedByCMD")

## Gains by mpc, curorg, grade, rcc
addWorksheet(wb, sheetName = "allGains")
addWorksheet(wb, sheetName = "gainsByMpc")
addWorksheet(wb, sheetName = "gainsByCurorg")
addWorksheet(wb, sheetName = "gainsByGrade")
addWorksheet(wb, sheetName = "gainsByRcc")

## Losses by reason, curorg, grade, mos
addWorksheet(wb, sheetName = "allLosses")
addWorksheet(wb, sheetName = "lossesByReason")
addWorksheet(wb, sheetName = "lossesByCurorg")
addWorksheet(wb, sheetName = "lossesByGrade")
addWorksheet(wb, sheetName = "lossesByMos")

## Write the data to the xlsx file
writeData(wb, "dash", txt_dt, startCol = 1, startRow = 1, rowNames = F, borders = "all", borderColour = "black")

writeDataTable(wb,"gainsByCMD", cmd_gain_tot, startCol = 1,startRow = 1)
writeDataTable(wb,"lossesByCMD", cmd_loss_tot, startCol = 1,startRow = 1)
writeDataTable(wb,"assignedByCMD", cmd_asg_tot, startCol = 1,startRow = 1)

writeDataTable(wb,"allGains", g_all, startCol = 1,startRow = 1)
writeDataTable(wb,"gainsByMpc", g_mpc, startCol = 1,startRow = 1)
writeDataTable(wb,"gainsByCurorg", g_cur, startCol = 1,startRow = 1)
writeDataTable(wb,"gainsByGrade", g_grd, startCol = 1,startRow = 1)
writeDataTable(wb,"gainsByRcc", g_rcc, startCol = 1,startRow = 1)

writeDataTable(wb,"allLosses", l_all, startCol = 1,startRow = 1)
writeDataTable(wb,"lossesByReason", l_rsn, startCol = 1,startRow = 1)
writeDataTable(wb,"lossesByCurorg", l_cur, startCol = 1,startRow = 1)
writeDataTable(wb,"lossesByGrade", l_grd, startCol = 1,startRow = 1)
writeDataTable(wb,"lossesByMos", l_mos, startCol = 1,startRow = 1)

## Save workbook to working directory
saveWorkbook(wb, file = paste0("attrition_dat.xlsx"), overwrite = TRUE)

rm(list=ls())


## Put SQL data into a data table
#ss <- as.data.table(str_fys(fy[1]))
#se <- as.data.table(str_fye(fy[1]))
#sm <- as.data.table(str_fye(fy[1], mo[1]))

#la <- as.data.table(losses_a(fy[1], mo[1]))
#lm <- as.data.table(losses_m(fy[1], mo[1]))

#ga <- as.data.table(gains_a(fy[1], mo[1]))
#gm <- as.data.table(gains_m(fy[1], mo[1]))


# Formatting cells / columns is allowed , but inserting / deleting columns is protected:
# protectWorksheet(wb, "S1",
#                  protect = TRUE,
#                  lockFormattingCells = FALSE, lockFormattingColumns = FALSE,
#                  lockInsertingColumns = TRUE, lockDeletingColumns = TRUE
# )

# sheetVisible(wb)
# sheetVisible(wb)[1] <- TRUE ## show sheet 1
# sheetVisible(wb)[2] <- FALSE ## hide sheet 2

