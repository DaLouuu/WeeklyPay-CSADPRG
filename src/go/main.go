package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Configuration struct {
	DailySalary      float64
	RegularWorkHours int
	WorkdaysPerWeek  int
	RestDaysPerWeek  int
}

// Rates holds multipliers for regular pay and overtime
type DayRates struct {
	BaseMultiplier float64
	DayOTRate      float64
	NightOTRate    float64
}

var RateMatrix = map[string]DayRates{
	"NORMAL": {
		BaseMultiplier: 1.00,
		DayOTRate:      1.25,
		NightOTRate:    1.375,
	},
	"REST": {
		BaseMultiplier: 1.30,
		DayOTRate:      1.69,
		NightOTRate:    1.859,
	},
	"SNWH": {
		BaseMultiplier: 1.30,
		DayOTRate:      1.69,
		NightOTRate:    1.859,
	},
	"SNWHR": {
		BaseMultiplier: 1.50,
		DayOTRate:      1.95,
		NightOTRate:    2.145,
	},
	"RH": {
		BaseMultiplier: 2.00,
		DayOTRate:      2.60,
		NightOTRate:    2.860,
	},
	"RHR": {
		BaseMultiplier: 2.60,
		DayOTRate:      3.38,
		NightOTRate:    3.718,
	},
}

func isValidTimeFormat(timeStr string) bool {
	if len(timeStr) != 4 {
		return false
	}
	_, err := time.Parse("1504", timeStr)
	return err == nil
}

func parseMilitaryMinutes(timeStr string) int {
	h, _ := strconv.Atoi(timeStr[:2])
	m, _ := strconv.Atoi(timeStr[2:])
	return h*60 + m
}

type DailyResult struct {
	DayNumber       int
	IsRestDay       bool
	IsAbsent        bool
	DayType         string
	WorkHours       int
	WorkMinutes     int
	DayOTHours      int
	NightOTHours    int
	Salary          float64
}

func calculateDayPayroll(config Configuration, day int, inTime, outTime, holidayType string) DailyResult {
	hourlyRate := config.DailySalary / float64(config.RegularWorkHours)
	isRestDay := day > config.WorkdaysPerWeek

	// Determine Day Key
	dayKey := "NORMAL"
	if isRestDay {
		if holidayType == "RH" {
			dayKey = "RHR"
		} else if holidayType == "SNWH" {
			dayKey = "SNWHR"
		} else {
			dayKey = "REST"
		}
	} else {
		if holidayType == "RH" {
			dayKey = "RH"
		} else if holidayType == "SNWH" {
			dayKey = "SNWH"
		} else {
			dayKey = "NORMAL"
		}
	}

	rates := RateMatrix[dayKey]

	// Check absence: when OUT time is 0900 (same as IN time)
	if outTime == inTime {
		salary := 0.0
		if isRestDay {
			// Per spec: On rest days, absent employees get regular daily salary
			salary = config.DailySalary
		}
		return DailyResult{
			DayNumber:    day,
			IsRestDay:    isRestDay,
			IsAbsent:     true,
			DayType:      dayKey,
			WorkHours:    0,
			WorkMinutes:  0,
			DayOTHours:   0,
			NightOTHours: 0,
			Salary:       salary,
		}
	}

	inMin := parseMilitaryMinutes(inTime)
	outMin := parseMilitaryMinutes(outTime)
	if outMin < inMin {
		outMin += 24 * 60 // Spans into next day
	}

	totalSpan := outMin - inMin
	// Subtract 1 unpaid hour of break time (60 mins)
	workedMinutes := totalSpan - 60
	if workedMinutes < 0 {
		workedMinutes = 0
	}

	workedHours := workedMinutes / 60
	remainMinutes := workedMinutes % 60

	// Overtime calculation
	totalOT := 0
	if workedHours > config.RegularWorkHours {
		totalOT = workedHours - config.RegularWorkHours
	}

	dayOT := 0
	nightOT := 0

	if totalOT > 0 {
		if totalOT <= 4 {
			dayOT = totalOT
			nightOT = 0
		} else {
			dayOT = 4
			nightOT = totalOT - 4
		}
	}

	basePay := config.DailySalary * rates.BaseMultiplier
	dayOTPay := float64(dayOT) * hourlyRate * rates.DayOTRate
	nightOTPay := float64(nightOT) * hourlyRate * rates.NightOTRate

	totalSalary := basePay + dayOTPay + nightOTPay

	return DailyResult{
		DayNumber:    day,
		IsRestDay:    isRestDay,
		IsAbsent:     false,
		DayType:      dayKey,
		WorkHours:    workedHours,
		WorkMinutes:  remainMinutes,
		DayOTHours:   dayOT,
		NightOTHours: nightOT,
		Salary:       totalSalary,
	}
}

func main() {
	config := Configuration{
		DailySalary:      500.0,
		RegularWorkHours: 8,
		WorkdaysPerWeek:  5,
		RestDaysPerWeek:  2,
	}

	scanner := bufio.NewScanner(os.Stdin)

	for {
		fmt.Println("\nPayroll Menu")
		fmt.Println("1. Generate Pay Roll")
		fmt.Println("2. Update Work Hours / Settings")
		fmt.Println("3. Exit")
		fmt.Print("Select Option: ")

		if !scanner.Scan() {
			break
		}
		choiceStr := strings.TrimSpace(scanner.Text())
		choice, err := strconv.Atoi(choiceStr)
		if err != nil {
			fmt.Println("Invalid input. Please enter a number.")
			continue
		}

		switch choice {
		case 1:
			fmt.Println("\n---------------------------------")
			fmt.Println("Generating Pay Roll....")
			fmt.Println("---------------------------------")
			fmt.Print("Enter Employee Name: ")
			if !scanner.Scan() {
				return
			}
			employeeName := strings.TrimSpace(scanner.Text())

			var dailyResults []DailyResult
			totalSalary := 0.0
			regularDaysPresent := 0
			restDaysPresent := 0
			totalDayOT := 0
			totalNightOT := 0

			totalDays := config.WorkdaysPerWeek + config.RestDaysPerWeek

			for day := 1; day <= totalDays; day++ {
				fmt.Println("---------------------------------")
				isRestDay := day > config.WorkdaysPerWeek
				if isRestDay {
					fmt.Printf("DAY %d (REST DAY)\n", day)
				} else {
					fmt.Printf("DAY %d\n", day)
				}
				fmt.Println("(if absent Enter 0900)")

				holidayType := ""
				fmt.Print("Is today a Holiday? (Y/N): ")
				if scanner.Scan() {
					isHol := strings.ToUpper(strings.TrimSpace(scanner.Text()))
					if isHol == "Y" {
						fmt.Print("Enter Holiday Type (HD for Regular Holiday, SNWH for Special Non-Working): ")
						if scanner.Scan() {
							ht := strings.ToUpper(strings.TrimSpace(scanner.Text()))
							if ht == "HD" || ht == "RH" {
								holidayType = "RH"
							} else if ht == "SNWH" || ht == "SNWD" {
								holidayType = "SNWH"
							}
						}
					}
				}

				outTime := ""
				for {
					fmt.Print("Enter OUT Time (HHMM): ")
					if !scanner.Scan() {
						return
					}
					outTime = strings.TrimSpace(scanner.Text())
					if isValidTimeFormat(outTime) {
						break
					}
					fmt.Println("Invalid format. Please enter time as HHMM (e.g. 1700, 0900).")
				}

				res := calculateDayPayroll(config, day, "0900", outTime, holidayType)
				dailyResults = append(dailyResults, res)
				totalSalary += res.Salary
				totalDayOT += res.DayOTHours
				totalNightOT += res.NightOTHours

				if !res.IsAbsent {
					if res.IsRestDay {
						restDaysPresent++
					} else {
						regularDaysPresent++
					}
				}

				fmt.Printf("Salary for the day: %.2f\n", res.Salary)
			}

			// Weekly Payroll Summary
			fmt.Println("---------------------------------")
			fmt.Println()
			fmt.Printf("\t%s's Weekly Payroll\n", employeeName)
			fmt.Printf("Number of (Regular) Days Present\t\t%d\n", regularDaysPresent)
			fmt.Printf("Number of (Rest) Days Present\t\t\t%d\n", restDaysPresent)
			fmt.Printf("Total Hours Overtime (Night Shift Overtime)\t%d (%d)\n", totalDayOT+totalNightOT, totalNightOT)
			fmt.Println("--------------------------------------------------------")
			fmt.Printf("Total Salary for the Week\t\t\t%.2f\n", totalSalary)
			fmt.Println()
			fmt.Println("------ENTER 0 TO RETURN TO MENU---------")
			scanner.Scan()

		case 2:
			fmt.Println("\n--- Configure Payroll Settings ---")
			fmt.Printf("Current Daily Salary: %.2f\n", config.DailySalary)
			fmt.Print("Enter new Daily Salary (or press Enter to keep current): ")
			if scanner.Scan() {
				val := strings.TrimSpace(scanner.Text())
				if val != "" {
					if s, err := strconv.ParseFloat(val, 64); err == nil && s > 0 {
						config.DailySalary = s
						fmt.Printf("Daily Salary updated to %.2f\n", config.DailySalary)
					}
				}
			}

			fmt.Printf("Current Regular Work Hours: %d\n", config.RegularWorkHours)
			fmt.Print("Enter new Regular Work Hours (or press Enter to keep current): ")
			if scanner.Scan() {
				val := strings.TrimSpace(scanner.Text())
				if val != "" {
					if h, err := strconv.Atoi(val); err == nil && h > 0 {
						config.RegularWorkHours = h
						fmt.Printf("Regular Work Hours updated to %d\n", config.RegularWorkHours)
					}
				}
			}

		case 3:
			fmt.Println("Exiting Weekly Payroll System. Goodbye!")
			return

		default:
			fmt.Println("Invalid choice. Please select 1, 2, or 3.")
		}
	}
}
