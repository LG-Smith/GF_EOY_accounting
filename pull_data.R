library(apsdFuns)
library(ROracle)
library(tidyverse)
library(lubridate)
library(openxlsx2)
library(janitor)
options(scipen = 999)
Sys.setenv(TZ='EST')

load("EOY_catch_wb.rds")

conn <- apsdFuns::roracle_login(key_name = "apsd", key_service = "DB01P", schema = "apsd")

start_date <- "'01-MAY-24'"
end_date <- "'30-APR-25'"
scal_start_date <- "'01-APR-24'"
scal_en_date <- "'31-MAR-25'"

cams_land <- "apsd.ls_cams_land_YE24"
cams_discard <- "apsd.ls_cams_discard_YE24"
cams_subtrip <- "apsd.ls_cams_subtrip_YE24"
cams_fishery_group <- "apsd.ls_cams_fishery_group_YE24"

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

other_acls <- read.csv("FY24_non_commercialGF_ACLs.csv")

ACL_wide <- ACLs |>
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

EOY_catch_acl <- EOY_catch_wb |>
  wb_add_data(sheet = "ACLs", x = dplyr::select(ACL_wide, -STOCK_ID), start_col = 2, start_row = 6, col_names = FALSE, na.string = "")


##### catch
commercial_catch <- ROracle::dbGetQuery(conn = conn, statement = str_replace_all(read_file("sql/commercial_catch.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip)))
YELGB_small_mesh <- ROracle::dbGetQuery(conn = conn, statement = str_replace_all(read_file("sql/YELGB_small_mesh.sql"),
                                                                                 c("XSTART_DATE" = start_date,
                                                                                   "XEND_DATE" = end_date,
                                                                                   "XCAMS_LAND" = cams_land,
                                                                                   "XCAMS_DISCARD" = cams_discard,
                                                                                   "XCAMS_SUBTRIP" = cams_subtrip,
                                                                                   "XCAMS_FISHERY_GROUP" = cams_fishery_group)))
recreational <- read.csv("FY24_recreational.csv")

othersub_landing <-



wb_save(EOY_catch_acl,
        file = "../../../../mnt/h-drive/quota_monitoring/northeast_multispecies/end_of_fishing_year/EOY2024/accounting_year_end/FY2024_mults_catch_estimates.xlsx")
