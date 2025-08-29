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

other_acls <- read.csv("data/FY24_non_commercialGF_ACLs.csv") ## put in oracle eventually

ACL_table <- ACLs |>
  mutate(across(where(is.numeric), round_half_up),
         SUB_ACL = case_when(STOCK_ID %in% c('FLGMGBSS','FLDSNEMA', 'OPTGMMA', 'HALGMMA', 'WOLGMMA') & SECTOR_GROUP == "SECT" ~ NA,
                             TRUE ~ SUB_ACL)) |>
  pivot_wider(names_from = SECTOR_GROUP, values_from = SUB_ACL) |>
  mutate(SECT_ACL = SECT,
         CP_ACL = CP) |>
  left_join(sort_order) |>
  left_join(other_acls) |>
  mutate(GF_ACL = CP_ACL + coalesce(SECT_ACL, 0) + coalesce(REC_ACL, 0),
         TOTAL_ACL = round_half_up(CP_ACL + coalesce(SECT_ACL, 0) + coalesce(REC_ACL, 0) + coalesce(HERRING_ACL, 0) +
           coalesce(SCALLOP_ACL, 0) + coalesce(SMM_ACL, 0) + coalesce(STATE_ACL, 0) + coalesce(OTHERSUB_ACL, 0))) |>
  arrange(PRINT_ORDER) |>
  select(STOCK_ID, TOTAL_ACL, GF_ACL, SECT_ACL, CP_ACL, REC_ACL, HERRING_ACL, SCALLOP_ACL, SMM_ACL, STATE_ACL, OTHERSUB_ACL)




##### pull catch data for various sub-ACLs
commercial_catch <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/commercial_catch.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip)))
small_mesh_catch <- ROracle::dbGetQuery(conn = conn,
                                        statement = str_replace_all(read_file("sql/small_mesh.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))
### Check confidentiality, add text NA or 0s as needed

smm_conf <- small_mesh_catch |>
  rbind(data.frame(STOCK_ID = "YELGB", LBS = 0.0, PERMITS = 0, SOURCE = 'LAND')) |>
  mutate(LBS = case_when(PERMITS > 0 & PERMITS < 3 ~ 'NA',
                         TRUE ~ as.character(LBS)))

#### do this part based on the confidentiality. For FY24 (can put 0), but discards are only 2 permits (NA)
smm_catch <- smm_conf |>
  select(-PERMITS) |>
  pivot_wider(names_from = 'SOURCE', values_from = 'LBS') |>
  mutate(SMM_CATCH = 'NA',
         SMM_DISCARD = 'NA',
         SMM_LAND = 0.0)


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


recreational <- read.csv("data/recreational.csv")


herring_placeholder <- read.csv("data/herring_placeholder.csv")



####### catch totals

rec_catch <- recreational |> ### these stocks have rec sub-ACLs so go in the table under recreational catch column
  filter(STOCK_ID %in% c("CODGMSS", "HADGM")) |>
  mutate(REC_CATCH = TOTAL_REMOVALS) |>
  select(STOCK_ID, REC_CATCH)

rec_catch_state <- recreational |> ### these rec values get added to the state column
  filter(!(STOCK_ID %in% c("CODGMSS", "HADGM"))) |>
  mutate(REC_STATE = TOTAL_REMOVALS) |>
  select(STOCK_ID, REC_STATE)


othersub_catch <- othersub_landing_sm |>
  left_join(othersub_discard_sm) |>
  mutate(OTHERSUB_CATCH = OTHERSUB_LAND + OTHERSUB_DISCARD)


state_catch <- state |>
  mutate(COMMERCIAL_STATE = round_half_up(CATCH, 1),
         STOCK_ID = case_when(STOCK_ID %in% c('CODGBW', 'CODGBE') ~ 'CODGB',
                              STOCK_ID %in% c('HADGBW', 'HADGBE') ~ 'HADGB',
                              TRUE ~ STOCK_ID)) |>
  left_join(rec_catch_state) |>
  mutate(STATE_CATCH = coalesce(COMMERCIAL_STATE, 0) + coalesce(REC_STATE, 0)) |>
  select(STOCK_ID, STATE_CATCH)

scal_catch <- scallop |>
  group_by(STOCK_ID) |>
  summarise(SCALLOP_CATCH = round_half_up(sum(MT, na.rm = TRUE), 1))

herring_catch_placeholder <- herring_placeholder |>
  mutate(STOCK_ID = if_else(STOCK_ID %in% c('HADGBW', "HADGBE"), 'HADGB', STOCK_ID)) |>
  group_by(STOCK_ID) |>
  summarise(HERRING_CATCH = sum(CATCH, na.rm = TRUE)) |>
  select(STOCK_ID, HERRING_CATCH)

### final table
catch_totals <- commercial_catch |>
  filter(!is.na(STOCK)) |>
  mutate(CATCH_MT = round_half_up(CATCH_MT, 1)) |>
  select(SECTOR_GROUP, STOCK, STOCK_ID, CATCH_MT, YE_SORT_ORDER) |>
  pivot_wider(names_from = SECTOR_GROUP, values_from = CATCH_MT) |>
  mutate(SECTOR_CATCH = SECTOR,
         CP_CATCH = COMMON_POOL) |>
  left_join(rec_catch) |>
  mutate(GF_FISHERY_CATCH = round_half_up(coalesce(COMMON_POOL, 0) + coalesce(SECTOR, 0) + coalesce(REC_CATCH, 0), 1)) |>
  left_join(select(othersub_catch, STOCK_ID, OTHERSUB_CATCH)) |>
  left_join(state_catch) |>
  left_join(scal_catch) |>
  left_join(herring_catch_placeholder) |>
  left_join(smm_catch) |>
  mutate(TOTAL_CATCH = coalesce(GF_FISHERY_CATCH, 0) + coalesce(HERRING_CATCH, 0) + coalesce(SCALLOP_CATCH, 0) + coalesce(OTHERSUB_CATCH, 0) + coalesce(STATE_CATCH, 0) + coalesce(as.numeric(SMM_CATCH), 0)) |>
  arrange(YE_SORT_ORDER) |>
  select(STOCK_ID, TOTAL_CATCH, GF_FISHERY_CATCH, SECTOR_CATCH, CP_CATCH, REC_CATCH, HERRING_CATCH, SCALLOP_CATCH, SMM_CATCH, STATE_CATCH, OTHERSUB_CATCH)

#### percents of sub_ACL







