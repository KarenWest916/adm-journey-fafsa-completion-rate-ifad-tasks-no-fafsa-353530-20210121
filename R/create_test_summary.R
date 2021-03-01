




create_test_summary <- function(tbl_name,
                                input_vars
                                ){
  
  # load package
  library(magrittr)
  library(gt)
  
  # table
  tibble::tibble(
    `  ` = c("North Star Metric", "Date Range", "Test Metric - Overall Result", "Recommendation"),
    ` `  = c(input_vars)
  ) %>% 
    gt() %>%
    tab_header(title = md("__Experiment Outcome__")) %>%
    cols_align(align = c("right"), columns = vars(` `)) %>% 
    tab_options(heading.align = "Left",
                table.background.color = "#efefef",
                column_labels.background.color = "black",
                heading.border.bottom.color = "black",
                heading.background.color = "#0a3370",
                table.width = 750) %>% 
    gtsave(path = here::here("imgs"),
           filename = paste0(tbl_name,"test_summary.png"))
  
}










