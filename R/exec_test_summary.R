



# import helper function
source(here::here("R","create_test_summary.R"))


# creates test summary table
create_test_summary(
  tbl_name = "no_fafsa_", # name of image
  save_folder = ".", # save folder location
  input_vars = c("New Starts",
                 "1/21/21 - 3/1/21", # Date range of test
                 " ", # Test result 
                 "TBD" ) # Recommendation
)


