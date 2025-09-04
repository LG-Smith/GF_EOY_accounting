######################################
## A Asci
## 8.27.25
## pull chunk of code from quota monitoring for haddock catch cap year end accounting
## then QA/QC in Oracle Developer (Haddock Bycatch QAQC.sql)
######################################

library(ROracle)
library(DBI)
library(readr)
library(keyring)

library(MAPS)
library(apsdFuns)
library(dplyr, warn.conflicts = FALSE)
library(dbplyr)
options(scipen = 999)
Sys.setenv(TZ = "EST")
Sys.setenv(ORA_SDTZ = "EST")
#Sys.setenv(TZ = "-05")
#Sys.setenv(ORA_SDTZ = "-05")

# unlock keyring
keyring::keyring_unlock("apsd")

# connect to apsd on DB01P
apsd_con <- apsdFuns::roracle_login(key_name = 'apsd', key_service = 'DB01P', schema = 'apsd')


############ Haddock in herring ###########################
## define GF fishing year
fy = 2024
report_type = 'YE'
comments = 'YEAREND'
report_week = '04-SEP-25'

## observed trips
dbExecute(apsd_con, "TRUNCATE TABLE hadd_obdbs_trips")
hadd_herr_obs_trips <- dbGetQuery(apsd_con, statement = gsub("&fy", fy, read_file("sql/bm_hadd_obdbs_trips.sql")))
dbCommit(apsd_con)

##Haddock Bycatch by observed Trip
dbExecute(apsd_con, "TRUNCATE TABLE hadd_obdbs_gb")
hadd_herr_obs_gb <- dbGetQuery(apsd_con, statement = read_file('sql/bm_hadd_obdbs_gb.sql'))
dbCommit(apsd_con)

dbExecute(apsd_con, "TRUNCATE TABLE hadd_obdbs_gom")
hadd_herr_obs_gom <- dbGetQuery(apsd_con, statement = read_file('sql/bm_hadd_obdbs_gom.sql'))
dbCommit(apsd_con)

##cams landings
dbExecute(apsd_con, "TRUNCATE TABLE hadd_cams_kall_gb")
hadd_herr_kall_gb <- dbGetQuery(apsd_con, statement = gsub("&fy", fy, read_file('sql/bm_hadd_cams_kall_gb.sql')))
dbCommit(apsd_con)

dbExecute(apsd_con, "TRUNCATE TABLE hadd_cams_kall_gom")
hadd_herr_kall_gom <- dbGetQuery(apsd_con, statement = gsub("&fy", fy, read_file('sql/bm_hadd_cams_kall_gom.sql')))
dbCommit(apsd_con)


##Replace CAMS RHS estimate w/Observer when available, Observer orphans ignored
dbExecute(apsd_con, "TRUNCATE TABLE hadd_final_gb")
hadd_herr_final_gb <- dbGetQuery(apsd_con, statement = read_file('sql/bm_hadd_final_gb.sql'))
dbCommit(apsd_con)

dbExecute(apsd_con, "TRUNCATE TABLE hadd_final_gom")
hadd_herr_final_gom <- dbGetQuery(apsd_con, statement = read_file('sql/bm_hadd_final_gom.sql'))
dbCommit(apsd_con)

##archive
dbGetQuery(apsd_con, statement = gsub("&report_type", report_type,
                                      gsub("&comments", comments,
                                           gsub("&report_week", report_week,
                                                read_file("sql/bm_hadd_archive_obdbs_trips.sql")))))
dbGetQuery(apsd_con, statement = gsub("&report_type", report_type,
                                      gsub("&comments", comments,
                                           gsub("&report_week", report_week,
                                                read_file("sql/bm_hadd_archive_obdbs.sql")))))
dbGetQuery(apsd_con, statement = gsub("&report_type", report_type,
                                      gsub("&comments", comments,
                                           gsub("&report_week", report_week,
                                                read_file("sql/bm_hadd_archive_cams_kall.sql")))))
dbGetQuery(apsd_con, statement = gsub("&report_type", report_type,
                                      gsub("&comments", comments,
                                           gsub("&report_week", report_week,
                                                read_file("sql/bm_hadd_archive_final.sql")))))

dbCommit(apsd_con)
ROracle::dbDisconnect(apsd_con)
