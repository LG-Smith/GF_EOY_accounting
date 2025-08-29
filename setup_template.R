library(tidyverse)
library(lubridate)
library(openxlsx2)
options(scipen = 999)
Sys.setenv(TZ='EST')

template <- wb_load(file = "catch_estimates_template.xlsx")

#### general pieces (update as needed)
fishing_year <- "2024"
source <- "Source: NMFS Greater Atlantic Regional Fisheries Office"
data_sources <- "These data are the best available to NOAA's National Marine Fisheries Service (NMFS). Data sources for this report include: (1) Vessels via VMS; (2) Vessels via vessel logbook reports; (3) Dealers via Dealer Electronic reporting; (4) Observers, at-sea monitors, and electronic monitoring via the Northeast Fisheries Observer Program. Differences with previous reports are due to corrections made to the database."
archive_date <- "July 17, 2025"
date <- today()
run_dates <- paste0(date, "; run date of ", archive_date)
unit <- "Values in metric tons of live weight"
non_allocated <- "Any value for a non-allocated species may include landings of that stock or misreporting of species and/or stock area. These are northern windowpane, southern windowpane, ocean pout, halibut, and wolffish."
fishery_groups <- "These criteria are used by the Greater Atlantic Regional Fisheries Office (GARFO) to categorize trips to attribute groundfish catch for groundfish ACL accounting. By necessity these rules cannot capture the full complexity of categorizing every trip taken by vessels fishing in the Northeast. Further analysis should be completed to definitively attribute groundfish catch to an FMP for management purposes."


#### sheet-specific details - read through and make sure nothing needs to be changed from one year to next
#### Sheet 1 : cover, table descriptions
Title <- "Northeast Multispecies Fishery"
subtitle <- paste0("Year-End Results for Fishing Year ", fishing_year)
table1_5 <- "Tables 1 through 5: Total groundfish caught, landed, and discard estimates"
table6 <- "Table 6: Estimated state water catch"
table7_9 <- "Tables 7-9: Other sub-component catch detail"
table10 <- "Table 10: FY 2021 through FY 2023 GOM cod and haddock recreational catch evaluation"
table11 <- "Table 11: Sector carryover table expected to be available soon"
table12_17 <- "Tables 12 through 17: U.S./Canada stocks catch evaluation"
zero_desc <- "In this report: a table cell value of '0' or '0.0' indicates a non-zero value in the cell. '-' is displayed for values exactly equal to zero. Blanks are shown when there are no values. 'NA' is displayed when no value is applicable or available."


EOY_catch_wb <- template |>
  wb_add_data(sheet = "Cover", Title, start_col = 2, start_row = 4) |>
  wb_add_data(sheet = "Cover", subtitle, start_col = 2, start_row = 6) |>
  wb_add_data(sheet = "Cover", table1_5, start_col = 1, start_row = 9) |>
  wb_add_data(sheet = "Cover", table6, start_col = 1, start_row = 11) |>
  wb_add_data(sheet = "Cover", table7_9, start_col = 1, start_row = 13) |>
  wb_add_data(sheet = "Cover", table10, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "Cover", table11, start_col = 1, start_row = 17) |>
  wb_add_data(sheet = "Cover", table12_17, start_col = 1, start_row = 19) |>
  wb_add_data(sheet = "Cover", zero_desc, start_col = 1, start_row = 23) |>
  wb_add_data(sheet = "Cover", source, start_col = 1, start_row = 26) |>
  wb_add_data(sheet = "Cover", date, start_col = 1, start_row = 27)


#### sheet 2: percent ACLs
title <- paste0("Table 1: FY ", fishing_year, " Northeast Multispecies Percent of Annual Catch Limit Caught (%)")

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Percent_ACLs", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "Percent_ACLs", source, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Percent_ACLs", run_dates, start_col = 1, start_row = 35) |>
  wb_add_data(sheet = "Percent_ACLs", data_sources, start_col = 1, start_row = 37)


#### sheet 3: ACLs
title <- paste0("Table 2: FY ", fishing_year, " Northeast Multispecies Annual Catch Limits (mt)")

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "ACLs", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "ACLs", unit, start_col = 1, start_row = 28) |>
  wb_add_data(sheet = "ACLs", source, start_col = 1, start_row = 30) |>
  wb_add_data(sheet = "ACLs", date, start_col = 1, start_row = 31)

##### sheet 4: catch
title <- paste0("Table 3: FY ", fishing_year, " Northeast Multispecies Total Catch (mt)")
scal <- paste0("\U00B9", "Based on scallop fishing year April ", as.character(as.integer(fishing_year)-1), " through March ", fishing_year)

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Catch", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "Catch", scal, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "Catch", unit, start_col = 1, start_row = 31) |>
  wb_add_data(sheet = "Catch", source, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Catch", run_dates, start_col = 1, start_row = 35) |>
  wb_add_data(sheet = "Catch", data_sources, start_col = 1, start_row = 36) |>
  wb_add_data(sheet = "Catch", non_allocated, start_col = 6, start_row = 30)

##### sheet 5:landings
title <- paste0("Table 4: FY ", fishing_year, " Northeast Multispecies Landings (mt)")


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Landings", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "Landings", unit, start_col = 1, start_row = 30) |>
  wb_add_data(sheet = "Landings", source, start_col = 1, start_row = 33) |>
  wb_add_data(sheet = "Landings", run_dates, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Landings", data_sources, start_col = 1, start_row = 35) |>
  wb_add_data(sheet = "Landings", non_allocated, start_col = 6, start_row = 30)


##### sheet 6: discards
title <- paste0("Table 5: FY ", fishing_year, " Northeast Multispecies Discards (mt)")


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Discards", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "Discards", unit, start_col = 1, start_row = 30) |>
  wb_add_data(sheet = "Discards", source, start_col = 1, start_row = 33) |>
  wb_add_data(sheet = "Discards", run_dates, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Discards", data_sources, start_col = 1, start_row = 35)


##### Sheet 7: State
title <- paste0("Table 6: FY ", fishing_year, " Northeast Multispecies Estimated State Water Sub-Component Catch Detail(mt)")
rec <- "*Recreational catch of GOM cod and haddock in state waters is attributed to the recreational sub-ACL (see Tables 1 - 5), and so is not included above."
Mass <- "Some stocks were attributed using Massachusetts logbook data"



EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "State_Detail", title, start_col = 1, start_row = 1) |>
  wb_add_data(sheet = "State_Detail", rec, start_col = 1, start_row = 27) |>
  wb_add_data(sheet = "State_Detail", Mass, start_col = 1, start_row = 28) |>
  wb_add_data(sheet = "State_Detail", unit, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "State_Detail", source, start_col = 1, start_row = 32) |>
  wb_add_data(sheet = "State_Detail", run_dates, start_col = 1, start_row = 33) |>
  wb_add_data(sheet = "State_Detail", data_sources, start_col = 1, start_row = 35)

#### sheet 8: catch by FMP

title <- title <- paste0("Table 7: FY ", fishing_year, " Northeast Multispecies Other Sub-Component Catch Detail(mt)")
landings_only <- paste0("\U00B2", "Landings only. Discard estimates not applicable. Lobster/crab discards were not attributed to the ACL, consistent with")
landings_only2 <- ("the most recent assessments for these stocks used to set the respective quotas.")
research <- paste0("\U00B3", "Accounting of research catch varies according to research program, consistent with MSA requirements and research permit policy.")
sep_subACL <- "*Some or all catch attributed to separate sub-ACL as shown in Tables 1 through 5, and so is not included above."


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Catch_by_FMP", title, start_col = 3, start_row = 3) |>
  wb_add_data(sheet = "Catch_by_FMP", title, start_col = 13, start_row = 3) |>
  wb_add_data(sheet = "Catch_by_FMP", unit, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "Catch_by_FMP", source, start_col = 1, start_row = 35) |>
  wb_add_data(sheet = "Catch_by_FMP", run_dates, start_col = 1, start_row = 37) |>
  wb_add_data(sheet = "Catch_by_FMP", scal, start_col = 3, start_row = 29) |>
  wb_add_data(sheet = "Catch_by_FMP", landings_only, start_col = 3, start_row = 30) |>
  wb_add_data(sheet = "Catch_by_FMP", landings_only2, start_col = 3, start_row = 31) |>
  wb_add_data(sheet = "Catch_by_FMP", research, start_col = 3, start_row = 32) |>
  wb_add_data(sheet = "Catch_by_FMP", sep_subACL, start_col = 3, start_row = 33) |>
  wb_add_data(sheet = "Catch_by_FMP", sep_subACL, start_col = 13, start_row = 33) |>
  wb_add_data(sheet = "Catch_by_FMP", fishery_groups, start_col = 3, start_row = 38) |>
  wb_add_data(sheet = "Catch_by_FMP", fishery_groups, start_col = 13, start_row = 38) |>
  wb_add_data(sheet = "Catch_by_FMP", data_sources, start_col = 3, start_row = 43) |>
  wb_add_data(sheet = "Catch_by_FMP", data_sources, start_col = 13, start_row = 43)

##### Sheet 9: landings by FMP

title <- paste0("Table 8: FY ", fishing_year, " Northeast Multispecies Other Sub-Component Landings Detail(mt)")
research <- paste0("\U00B2", "Accounting of research catch varies according to research program, consistent with MSA requirements and research permit policy.")
sep_subACL <- "*Some or all catch attributed to separate sub-ACL as shown in Tables 1 through 5, and so is not included above."


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Landings_by_FMP", title, start_col = 3, start_row = 3) |>
  wb_add_data(sheet = "Landings_by_FMP", title, start_col = 13, start_row = 3) |>
  wb_add_data(sheet = "Landings_by_FMP", unit, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "Landings_by_FMP", source, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Landings_by_FMP", run_dates, start_col = 1, start_row = 36) |>
  wb_add_data(sheet = "Landings_by_FMP", scal, start_col = 3, start_row = 29) |>
  wb_add_data(sheet = "Landings_by_FMP", research, start_col = 3, start_row = 30) |>
  wb_add_data(sheet = "Landings_by_FMP", sep_subACL, start_col = 3, start_row = 31) |>
  wb_add_data(sheet = "Landings_by_FMP", sep_subACL, start_col = 13, start_row = 31) |>
  wb_add_data(sheet = "Landings_by_FMP", fishery_groups, start_col = 3, start_row = 36) |>
  wb_add_data(sheet = "Landings_by_FMP", fishery_groups, start_col = 13, start_row = 36) |>
  wb_add_data(sheet = "Landings_by_FMP", data_sources, start_col = 3, start_row = 41) |>
  wb_add_data(sheet = "Landings_by_FMP", data_sources, start_col = 13, start_row = 41)

##### Sheet 10: Discards by FMP

title <- paste0("Table 9: FY ", fishing_year, " Northeast Multispecies Other Sub-Component Discard Detail(mt)")
discards_NA <- paste0("\U00B2", "Discard estimates not applicable. Lobster/crab discards were not attributed to the ACL, consistent with the most recent assessments")
discards_NA2 <- "for these stocks used to set the respective quotas."
research <- paste0("\U00B3", "Accounting of research catch varies according to research program, consistent with MSA requirements and research permit policy.")
sep_subACL <- "*Some or all catch attributed to separate sub-ACL as shown in Tables 1 through 5, and so is not included above."


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Discards_by_FMP", title, start_col = 3, start_row = 3) |>
  wb_add_data(sheet = "Discards_by_FMP", title, start_col = 13, start_row = 3) |>
  wb_add_data(sheet = "Discards_by_FMP", unit, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "Discards_by_FMP", source, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Discards_by_FMP", run_dates, start_col = 1, start_row = 36) |>
  wb_add_data(sheet = "Discards_by_FMP", scal, start_col = 3, start_row = 29) |>
  wb_add_data(sheet = "Discards_by_FMP", discards_NA, start_col = 3, start_row = 30) |>
  wb_add_data(sheet = "Discards_by_FMP", discards_NA2, start_col = 3, start_row = 31) |>
  wb_add_data(sheet = "Discards_by_FMP", research, start_col = 3, start_row = 32) |>
  wb_add_data(sheet = "Discards_by_FMP", sep_subACL, start_col = 3, start_row = 33) |>
  wb_add_data(sheet = "Discards_by_FMP", sep_subACL, start_col = 13, start_row = 33) |>
  wb_add_data(sheet = "Discards_by_FMP", fishery_groups, start_col = 3, start_row = 36) |>
  wb_add_data(sheet = "Discards_by_FMP", fishery_groups, start_col = 13, start_row = 36) |>
  wb_add_data(sheet = "Discards_by_FMP", data_sources, start_col = 3, start_row = 41) |>
  wb_add_data(sheet = "Discards_by_FMP", data_sources, start_col = 13, start_row = 41)


##### sheet 11: GOM cod and haddock rec catch

rec_start_year <- as.character(as.integer(fishing_year) - 2)
title <- paste0("Table 10: FY ", rec_start_year, "-", fishing_year, " GOM Cod and Haddock Recreational Catch Evaluation (mt)")
mrip <- "Recreational estimates based on Marine Recreational Information Program(MRIP) data."
FES <- "GOM Cod and GOM Haddock recreational catch estimates are based on the Fishery Effort Survey (FES)"
best_available <- "These data are the best available to NOAA's National Marine Fisheries Service (NMFS)"

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Recreational_Catch", title, start_col = 2, start_row = 1) |>
  wb_add_data(sheet = "Recreational_Catch", mrip, start_col = 2, start_row = 21) |>
  wb_add_data(sheet = "Recreational_Catch", FES, start_col = 2, start_row = 22) |>
  wb_add_data(sheet = "Recreational_Catch", unit, start_col = 2, start_row = 23) |>
  wb_add_data(sheet = "Recreational_Catch", source, start_col = 2, start_row = 25) |>
  wb_add_data(sheet = "Recreational_Catch", date, start_col = 2, start_row = 26) |>
  wb_add_data(sheet = "Recreational_Catch", best_available, start_col = 2, start_row = 28)

##### sheet 12: Carryover
title <- paste0("Table 11: FY ", fishing_year, " Northeast Multispecies Sector Carryover (mt)")
gb_flounder <- "*Carryover of GB yellowtail flounder is not allowed because this stock is jointly managed with Canada."
non_allocated_carryover <- "**There is no carryover for non-allocated stocks: Northern windowpane flounder, southern windowpane flounder, ocean pout, halibut, and wolffish."

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "Carryover", title, start_col = 2, start_row = 1) |>
  wb_add_data(sheet = "Carryover", gb_flounder, start_col = 1, start_row = 28) |>
  wb_add_data(sheet = "Carryover", non_allocated_carryover, start_col = 1, start_row = 29) |>
  wb_add_data(sheet = "Carryover", data_sources, start_col = 1, start_row = 31) |>
  wb_add_data(sheet = "Carryover", source, start_col = 1, start_row = 34) |>
  wb_add_data(sheet = "Carryover", date, start_col = 7, start_row = 34)


##### sheet 13: US Canada Percent of ACLs

title <- paste0("Table 12: FY ", fishing_year, " End of Year Accounting of Transboundary U.S./Canada Stocks - Percentage of U.S. TACs Caught (%)")
percs <- "Values in percent live weight (%)"
conf <- "'NA' amounts not available due to confidentiality"
non_allocated_sm <- "Any value for a non-allocated species may be due to catch of that stock and/or misreporting of species and/or stock area.."

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", title, start_col = 2, start_row = 2) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", percs, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", conf, start_col = 1, start_row = 16) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", source, start_col = 1, start_row = 17) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", date, start_col = 1, start_row = 18) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", data_sources, start_col = 1, start_row = 20) |>
  wb_add_data(sheet = "US_Canada_Percent_of_ACLs", non_allocated_sm, start_col = 8, start_row = 15)

##### sheet 14: US Canada Sub-ACLs

title <- paste0("Table 13: FY ", fishing_year, " End of Year Accounting of Transboundary U.S./Canada Stocks- U.S. TACs (mt)")

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "US_Canada_sub_ACLs", title, start_col = 2, start_row = 3) |>
  wb_add_data(sheet = "US_Canada_sub_ACLs", unit, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "US_Canada_sub_ACLs", source, start_col = 1, start_row = 17) |>
  wb_add_data(sheet = "US_Canada_sub_ACLs", date, start_col = 1, start_row = 18)

##### sheet 15: US Canada Catch
title14 <- paste0("Table 14: FY ", fishing_year, " End of Year Accounting of Transboundary U.S./Canada Stocks - U.S. Catch (mt)")
title15 <- paste0("Table 15: FY ", fishing_year, " End of Year Transboundary U.S./Canada Vessels, Trips, DAS Used and Observers")
area <- paste0("\U00B9", "Area based on area fished. Totals don't sum due to multi-area trips")

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "US_Canada_Catch", title14, start_col = 1, start_row = 3) |>
  wb_add_data(sheet = "US_Canada_Catch", title15, start_col = 1, start_row = 20) |>
  wb_add_data(sheet = "US_Canada_Catch", unit, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "US_Canada_Catch", conf, start_col = 1, start_row = 16) |>
  wb_add_data(sheet = "US_Canada_Catch", date, start_col = 1, start_row = 18) |>
  wb_add_data(sheet = "US_Canada_Catch", area, start_col = 1, start_row = 28) |>
  wb_add_data(sheet = "US_Canada_Catch", conf, start_col = 1, start_row = 30) |>
  wb_add_data(sheet = "US_Canada_Catch", source, start_col = 1, start_row = 32) |>
  wb_add_data(sheet = "US_Canada_Catch", date, start_col = 1, start_row = 33) |>
  wb_add_data(sheet = "US_Canada_Catch", data_sources, start_col = 1, start_row = 36) |>
  wb_add_data(sheet = "US_Canada_Catch", non_allocated_sm, start_col = 5, start_row = 32)


##### sheet 16: US Canada Landings
title <- paste0("Table 16: FY ", fishing_year, " End of Year Accounting of Transboundary U.S./Canada Stocks - U.S. Landings (mt)")

EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "US_Canada_Landings", title, start_col = 1, start_row = 3) |>
  wb_add_data(sheet = "US_Canada_Landings", unit, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "US_Canada_Landings", conf, start_col = 1, start_row = 16) |>
  wb_add_data(sheet = "US_Canada_Landings", source, start_col = 1, start_row = 17) |>
  wb_add_data(sheet = "US_Canada_Landings", date, start_col = 1, start_row = 18) |>
  wb_add_data(sheet = "US_Canada_Landings", data_sources, start_col = 1, start_row = 20) |>
  wb_add_data(sheet = "US_Canada_Landings", non_allocated_sm, start_col = 8, start_row = 15)

##### sheet 17: US Canada Discards
title <- paste0("Table 17: FY ", fishing_year, " End of Year Accounting of Transboundary U.S./Canada Stocks - U.S. Discards (mt)")


EOY_catch_wb <- EOY_catch_wb |>
  wb_add_data(sheet = "US_Canada_Discards", title, start_col = 1, start_row = 3) |>
  wb_add_data(sheet = "US_Canada_Discards", unit, start_col = 1, start_row = 15) |>
  wb_add_data(sheet = "US_Canada_Discards", conf, start_col = 1, start_row = 16) |>
  wb_add_data(sheet = "US_Canada_Discards", source, start_col = 1, start_row = 17) |>
  wb_add_data(sheet = "US_Canada_Discards", date, start_col = 1, start_row = 18) |>
  wb_add_data(sheet = "US_Canada_Discards", data_sources, start_col = 1, start_row = 20) |>
  wb_add_data(sheet = "US_Canada_Discards", non_allocated_sm, start_col = 8, start_row = 15)

save(EOY_catch_wb, file = "EOY_catch_wb.rds")
wb_save(EOY_catch_wb,
        file = "../../../../mnt/h-drive/quota_monitoring/northeast_multispecies/end_of_fishing_year/EOY2024/accounting_year_end/FY2024_mults_catch_estimates.xlsx")

rm(list = ls())
gc()
