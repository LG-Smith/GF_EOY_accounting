

EOY_catch_acl <- EOY_catch_wb |>
  wb_add_data(sheet = "ACLs", x = dplyr::select(ACL_wide, -STOCK_ID), start_col = 2, start_row = 6, col_names = FALSE, na.string = "")
