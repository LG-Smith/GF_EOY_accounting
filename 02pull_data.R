library(apsdFuns)
library(ROracle)
library(tidyverse)
library(lubridate)
library(openxlsx2)
library(janitor)
options(scipen = 999)
Sys.setenv(TZ='EST')

#load("EOY_catch_wb.rds")

conn <- apsdFuns::roracle_login(key_name = "apsd", key_service = "DB01P", schema = "apsd")

###### establish groundfish year for year-end summaries
fy_year <- 2024  ### just change this

fy_end_year <- fy_year + 1
fy_year_sm <- substr(fy_year, 3, 4)
fy_end_sm <- substr(fy_end_year, 3, 4)
start_date <- paste0("'01-MAY-", fy_year_sm, "'")
end_date <- paste0("'30-APR-", fy_end_sm, "'")
scal_start_date <- paste0("'01-APR-", fy_year_sm, "'")
scal_end_date <- paste0("'31-MAR-", fy_end_sm, "'")

##### update locations of archive tables
cams_land <- "apsd.ls_cams_land_YE24"
cams_discard <- "apsd.ls_cams_discard_YE24"
cams_subtrip <- "apsd.ls_cams_subtrip_YE24"
cams_fishery_group <- "apsd.ls_cams_fishery_group_YE24"



#### get standard order of groundfish stocks for tables
sort_order <- ROracle::dbGetQuery(conn = conn, statement = "SELECT stock_id, stock_name, print_order
                                  FROM apsd.t_sectors_mul_print")

#### Get ACLs from t_mul_acl table (commercial gf) and from regs

ACLs <- ROracle::dbGetQuery(conn = conn, statement = "SELECT ap_year
, sector_group
, stock_id
, sum(sub_acl) sub_acl
FROM apsd.t_mul_acls
WHERE ap_year = 2024
AND stock_id NOT IN ('CODGBE', 'CODGBW', 'HADGBE', 'HADGBW')
GROUP BY ap_year, sector_group, stock_id")

other_acls <- read.csv("FY24_non_commercialGF_ACLs.csv") ## put in oracle eventually

ACL_table <- ACLs |>
  mutate(across(where(is.numeric), round_half_up),
         SUB_ACL = case_when(STOCK_ID %in% c('FLGMGBSS','FLDSNEMA', 'OPTGMMA', 'HALGMMA', 'WOLGMMA') & SECTOR_GROUP == "SECT" ~ NA,
                             TRUE ~ SUB_ACL)) |>
  pivot_wider(names_from = SECTOR_GROUP, values_from = SUB_ACL) |>
  left_join(sort_order) |>
  left_join(other_acls) |>
  mutate(commercial_total = CP + coalesce(SECT, 0) + coalesce(rec, 0),
         total = round_half_up(CP + coalesce(SECT, 0) + coalesce(rec, 0) + coalesce(Midwater, 0) +
           coalesce(Scallop, 0) + coalesce(Small_Mesh, 0) + coalesce(State, 0) + coalesce(Other, 0))) |>
  arrange(PRINT_ORDER) |>
  select(STOCK_ID, total, commercial_total, SECT, CP, rec, Midwater, Scallop, Small_Mesh, State, Other)




##### pull catch data for various sub-ACLs
commercial_catch <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/commercial_catch.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip)))
YELGB_small_mesh <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/YELGB_small_mesh.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))

scallop <- ROracle::dbGetQuery(conn = conn,
                               statement = str_replace_all(read_file("sql/scallop.sql"),
                                                                                 c("XSCAL_START_DATE" = start_date,
                                                                                   "XSCAL_END_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))

othersub_landing <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/othersub_landings.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XSCAL_START_DATE" = scal_start_date,
                                                                                   "XSCAL_END_DATE" = scal_end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))
othersub_landing_long <- othersub_landing |>
  select(-c(SYSDATE, FY, YE_SORT_ORDER)) |>
  pivot_longer(-c(STOCK_ID), names_to = "FISHERY_GROUP", values_to = "LAND_MT") |>
  ungroup()

othersub_landing_sm <- othersub_landing_long |>
  group_by(STOCK_ID) |>
  summarise(OTHERSUB_LAND = round_half_up(sum(LAND_MT, na.rm = TRUE), 1))


othersub_discard <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/othersub_discards.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XSCAL_START_DATE" = scal_start_date,
                                                                                   "XSCAL_END_DATE" = scal_end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))


othersub_discard_long <- othersub_discard |>
  select(-c(SYSDATE, FY, YE_SORT_ORDER)) |>
  pivot_longer(-c(STOCK_ID), names_to = "FISHERY_GROUP", values_to = "DISCARD_MT") |>
  ungroup()

othersub_discard_sm <- othersub_discard_long |>
  group_by(STOCK_ID) |>
  summarise(OTHERSUB_DISCARD = round_half_up(sum(DISCARD_MT, na.rm = TRUE), 1))



state <- ROracle::dbGetQuery(conn = conn, statement = str_replace_all(read_file("sql/state.sql"),
                                                                      c("XSTART_DATE" = start_date,
                                                                        "XEND_DATE" = end_date,
                                                                        "XCAMS_LAND" = cams_land,
                                                                        "XCAMS_DISCARD" = cams_discard,
                                                                        "XCAMS_SUBTRIP" = cams_subtrip,
                                                                        "XCAMS_FISHERY_GROUP" = cams_fishery_group)))

US_CA <- ROracle::dbGetQuery(conn = conn, statement = str_replace_all(read_file("sql/US_CA.sql"),
                                                                      c("XSTART_DATE" = start_date,
                                                                        "XEND_DATE" = end_date,
                                                                        "XCAMS_LAND" = cams_land,
                                                                        "XCAMS_DISCARD" = cams_discard,
                                                                        "XCAMS_SUBTRIP" = cams_subtrip,
                                                                        "XCAMS_FISHERY_GROUP" = cams_fishery_group)))


recreational <- read.csv("FY24_recreational.csv")


herring_placeholder <- read.csv("herring_placeholder.csv")
####### catch totals

rec_catch <- recreational |>
  filter(STOCK_NAME %in%c("GOM Cod", "GOM Haddock")) |>
  mutate(REC = TOTAL_REMOVALS) |>
  select(STOCK_NAME, REC)


othersub_catch <- othersub_landing_sm |>
  left_join(othersub_discard_sm) |>
  mutate(OTHERSUB_CATCH = OTHERSUB_LAND + OTHERSUB_DISCARD)


state_catch <- state |>
  mutate(STATE_CATCH = round_half_up(CATCH, 1),
         STOCK_ID = case_when(STOCK_ID %in% c('CODGBW', 'CODGBE') ~ 'CODGB',
                              STOCK_ID %in% c('HADGBW', 'HADGBE') ~ 'HADGB',
                              TRUE ~ STOCK_ID)) |>
  select(STOCK_ID, STATE_CATCH)

scal_catch <-

catch_totals <- commercial_catch |>
  filter(!is.na(STOCK)) |>
  mutate(CATCH_MT = round_half_up(CATCH_MT, 1)) |>
  select(SECTOR_GROUP, STOCK, STOCK_ID, CATCH_MT, YE_SORT_ORDER) |>
  pivot_wider(names_from = SECTOR_GROUP, values_from = CATCH_MT) |>
  left_join(rec_catch, by = c("STOCK" = "STOCK_NAME")) |>
  mutate(GF_FISHERY = round_half_up(COMMON_POOL + SECTOR + coalesce(REC, 0), 1)) |>
  left_join(select(othersub_catch, STOCK_ID, OTHERSUB_CATCH)) |>
  left_join(state_catch)






