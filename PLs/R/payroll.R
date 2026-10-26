# ==============================================================================
# CSADPRG - Comparative Study of Programming Languages
# Language: R
# Paradigm: Functional, Statistical / Array-Oriented
# Component: Weekly Payroll System
# ==============================================================================

rate_matrix <- list(
  "Normal Day" = list(base = 1.00, ot_day = 1.25, ot_night = 1.375),
  "Rest Day" = list(base = 1.30, ot_day = 1.69, ot_night = 1.859),
  "Special Non-Working Day" = list(base = 1.30, ot_day = 1.69, ot_night = 1.859),
  "SNWH" = list(base = 1.30, ot_day = 1.69, ot_night = 1.859),
  "Special Non-Working Day and Rest Day" = list(base = 1.50, ot_day = 1.95, ot_night = 2.145),
  "SNWHR" = list(base = 1.50, ot_day = 1.95, ot_night = 2.145),
  "Regular Holiday" = list(base = 2.00, ot_day = 2.60, ot_night = 2.860),
  "RH" = list(base = 2.00, ot_day = 2.60, ot_night = 2.860),
  "Regular Holiday and Rest Day" = list(base = 2.60, ot_day = 3.38, ot_night = 3.718),
  "RHR" = list(base = 2.60, ot_day = 3.38, ot_night = 3.718)
)

calculate_day_salary <- function(daily_salary = 500, in_time = 900, out_time = 900, day_type = "Normal Day", is_rest_day = FALSE) {
  hourly_rate <- daily_salary / 8.0

  # Absent Check (0900 IN and 0900 OUT)
  if (in_time == out_time) {
    if (is_rest_day) {
      return(list(salary = daily_salary, day_ot = 0, night_ot = 0, present = FALSE))
    } else {
      return(list(salary = 0.0, day_ot = 0, night_ot = 0, present = FALSE))
    }
  }

  in_h <- floor(in_time / 100)
  in_m <- in_time %% 100
  out_h <- floor(out_time / 100)
  out_m <- out_time %% 100

  in_total <- in_h * 60 + in_m
  out_total <- out_h * 60 + out_m
  if (out_total < in_total) {
    out_total <- out_total + 24 * 60
  }

  span_minutes <- out_total - in_total
  worked_minutes <- max(0, span_minutes - 60) # 1 unpaid break hour
  worked_hours <- floor(worked_minutes / 60)

  total_ot <- max(0, worked_hours - 8)
  day_ot <- min(4, total_ot)
  night_ot <- max(0, total_ot - 4)

  rates <- rate_matrix[[day_type]]
  if (is.null(rates)) {
    rates <- rate_matrix[["Normal Day"]]
  }

  base_pay <- daily_salary * rates$base
  day_ot_pay <- day_ot * hourly_rate * rates$ot_day
  night_ot_pay <- night_ot * hourly_rate * rates$ot_night

  total_pay <- base_pay + day_ot_pay + night_ot_pay

  return(list(
    salary = total_pay,
    day_ot = day_ot,
    night_ot = night_ot,
    present = TRUE
  ))
}

run_payroll_menu <- function() {
  cat("\n=========================================\n")
  cat("     WEEKLY PAYROLL SYSTEM (R Engine)\n")
  cat("=========================================\n")
  cat("1. Generate Payroll\n")
  cat("2. Exit\n")
  cat("Select Option: ")

  choice <- readline()
  if (choice == "1") {
    cat("\nEnter Employee Name: ")
    emp_name <- readline()

    daily_salary <- 500.0
    total_weekly <- 0.0
    reg_days_present <- 0
    rest_days_present <- 0
    total_day_ot <- 0
    total_night_ot <- 0

    for (day in 1:7) {
      cat(sprintf("\n---------------------------------\nDAY %d %s\n", day, ifelse(day >= 6, "(REST DAY)", "")))
      cat("Enter OUT Time (HHMM, 0900 if absent): ")
      out_str <- readline()
      out_time <- as.integer(out_str)

      day_type <- "Normal Day"
      if (day >= 6) {
        day_type <- "Rest Day"
      }
      cat(sprintf("Enter Day Type [Press Enter for '%s']: ", day_type))
      input_type <- readline()
      if (nchar(trimws(input_type)) > 0) {
        day_type <- trimws(input_type)
      }

      res <- calculate_day_salary(daily_salary, 900, out_time, day_type, is_rest_day = (day >= 6))
      total_weekly <- total_weekly + res$salary
      total_day_ot <- total_day_ot + res$day_ot
      total_night_ot <- total_night_ot + res$night_ot

      if (res$present) {
        if (day >= 6) {
          rest_days_present <- rest_days_present + 1
        } else {
          reg_days_present <- reg_days_present + 1
        }
      }

      cat(sprintf("Salary for Day %d: %.2f\n", day, res$salary))
    }

    cat("\n--------------------------------------------------------\n")
    cat(sprintf("\t%s's Weekly Payroll\n", emp_name))
    cat(sprintf("Number of (Regular) Days Present:             %d\n", reg_days_present))
    cat(sprintf("Number of (Rest) Days Present:                %d\n", rest_days_present))
    cat(sprintf("Total Hours Overtime (Night Shift Overtime):  %d (%d)\n", total_day_ot + total_night_ot, total_night_ot))
    cat("--------------------------------------------------------\n")
    cat(sprintf("Total Salary for the Week:                    %.2f\n", total_weekly))
    cat("--------------------------------------------------------\n")
  }
}

if (!interactive()) {
  run_payroll_menu()
}
