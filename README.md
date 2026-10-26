# WeeklyPay-CSADPRG: Weekly Payroll System

An automated, multi-paradigm Weekly Payroll System developed for **CSADPRG (Comparative Study of Programming Languages)**. This project evaluates language constructs, paradigms, and design ergonomics across **Go**, **Kotlin**, **Ruby**, and **R** by implementing an automated labor payroll engine complying with Philippine labor standards and course specifications.

---

## 📌 Table of Contents
1. [Project Overview](#-project-overview)
2. [Labor Standards & Computation Rules](#-labor-standards--computation-rules)
   - [Shift & Break Schedules](#shift--break-schedules)
   - [Rate Multipliers Matrix](#rate-multipliers-matrix)
   - [Overtime & Night Shift Differential](#overtime--night-shift-differential)
   - [Absence Handling](#absence-handling)
3. [Language Implementations & Paradigms](#-language-implementations--paradigms)
4. [Frontend Evaluation](#-frontend-evaluation)
5. [Code Audit & Resolved Issues](#-code-audit--resolved-issues)
6. [Project Folder Hierarchy](#-project-folder-hierarchy)
7. [How to Run](#-how-to-run)
8. [Automated Verification Tests](#-automated-verification-tests)
9. [Sample Input & Output](#-sample-input--output)

---

## 📖 Project Overview

Manual payroll calculation is vulnerable to human error, particularly when managing overlapping wage modifiers such as rest day premiums, special non-working days, regular holidays, overtime, and night shift differentials. 

This repository implements a **menu-driven Weekly Payroll System** that accepts employee working hours (in military time format `HHMM`), dynamically calculates daily compensation and overtime splits, and aggregates weekly earnings with detailed summaries.

---

## ⚖️ Labor Standards & Computation Rules

### Shift & Break Schedules
- **Default Work Schedule**: Starts at `0900` (9:00 AM) and ends at `1800` (6:00 PM) for an 8-hour shift.
- **Break Period**: 1 unpaid continuous hour of meal break is deducted from total duration for shifts exceeding 4 hours.
- **Night Shift Window**: Any work falling between `2200` (10:00 PM) and `0600` (6:00 AM) receives a **10% Night Shift Differential (DIFF)**.
- **Base Formula**:
  $$\text{Hourly Rate} = \frac{\text{Daily Salary}}{\text{Regular Hours per Day}} = \frac{500.00}{8} = 62.50\,\text{PHP/hr}$$

### Rate Multipliers Matrix

| Day Classification | Regular Pay Multiplier (≤ 8 hrs) | Non-Night Shift OT (1800–2200) | Night Shift OT (2200–0600) |
| :--- | :---: | :---: | :---: |
| **Normal Day** | 100% (`1.00`) | 125% (`1.25`) | 137.5% (`1.375`) |
| **Rest Day** | 130% (`1.30`) | 169% (`1.69`) | 185.9% (`1.859`) |
| **Special Non-Working Day (SNWH / SNWD)** | 130% (`1.30`) | 169% (`1.69`) | 185.9% (`1.859`) |
| **Special Non-Working Day & Rest Day (SNWHR)** | 150% (`1.50`) | 195% (`1.95`) | 214.5% (`2.145`) |
| **Regular Holiday (RH)** | 200% (`2.00`) | 260% (`2.60`) | 286.0% (`2.860`) |
| **Regular Holiday & Rest Day (RHR)** | 260% (`2.60`) | 338% (`3.38`) | 371.8% (`3.718`) |

### Overtime & Night Shift Differential
- Hours beyond 8 worked hours are categorized as overtime.
- The first 4 hours of overtime (typically 18:00 to 22:00) utilize the **Non-Night Shift Overtime Rate**.
- Overtime exceeding 4 hours (past 22:00) transitions into **Night Shift Overtime Rate** (combining the overtime multiplier and 10% night differential).

### Absence Handling
- An employee is marked **absent** if the entered OUT time equals the IN time (`0900`).
- **Normal Day Absence**: Salary = `0.00 PHP` (No work, no pay).
- **Rest Day Absence**: The employee is not required to work; if configured as an unworked rest day, base daily pay is `500.00 PHP` (or `0.00 PHP` if calculated strictly on rendered days).

---

## 💻 Language Implementations & Paradigms

| Language | Location | Paradigm / Focus | Key Concepts Demonstrated |
| :--- | :--- | :--- | :--- |
| **Go** | [`src/go/main.go`](src/go/main.go) | Procedural / Concurrent / Systems | Structs, slices, procedural pipelines, strong typing, zero-cost abstractions |
| **Kotlin** | [`src/kotlin/main.kt`](src/kotlin/main.kt) | Modern OOP / Functional | Type safety, null safety, data classes, expression evaluation |
| **Ruby** | [`src/ruby/main.rb`](src/ruby/main.rb) | Pure Object-Oriented / Dynamic | Class-based models (`Worker`, `Workday`), encapsulation, dynamic dispatch |
| **R** | [`src/r/main.R`](src/r/main.R) | Functional / Vectorized / Statistical | Named lists, vector indexing, functional transformations |

---

## 🖥️ Frontend Evaluation

### Does this project have a Frontend?
- **Current Status: No graphical or web frontend exists.**
- All implementations are **pure Command-Line Interface (CLI) / terminal menu-driven applications**, conforming to the CSADPRG course specification requirements.

### Recommended Frontend Enhancements (Optional Roadmap)
If expanding beyond the console terminal:
1. **Web Dashboard**: A lightweight frontend built with HTML5, CSS3, and JavaScript or React with Vite, displaying a weekly calendar timecard grid with instant gross pay recalculation.
2. **Desktop GUI**: A cross-platform desktop UI using Kotlin Desktop (Compose) or Go Fyne.

---

## 🛠️ Code Audit & Resolved Issues

During code review and testing, several critical defects and discrepancies were identified and resolved across the implementations:

### 1. Go Implementation (`src/go/main.go`)
- ❌ **Duplicate Menu Option & Crash**: Menu displayed option 2 as `Generate Pay Roll`, but selecting 2 immediately terminated the application (`Exit`), while option 3 threw an invalid choice error.
  - ✅ **Fixed**: Standardized menu options (1: Generate Payroll, 2: Update Settings, 3: Exit).
- ❌ **Skipped Workdays**: The loop ran `for day := 5; day <= 7; day++`, skipping Days 1 through 4 entirely.
  - ✅ **Fixed**: Corrected loop to iterate through all 7 days (`day := 1; day <= totalDays; day++`).
- ❌ **Absence Duration Overflow**: For absent days (`0900` to `0900`), `workHours := int(duration.Hours()) - 1` evaluated to `-1`, which under `workHours += 24` was incorrectly calculated as 23 hours of overtime!
  - ✅ **Fixed**: Explicit absence validation where `outTime == inTime` properly assigns 0 work hours and no overtime.
- ❌ **Missing Weekly Summary**: Daily pay was printed but weekly totals and present-day counters were never accumulated.
  - ✅ **Fixed**: Added complete summary tracking regular days present, rest days present, overtime hours split, and weekly gross total.

### 2. Kotlin Implementation (`src/kotlin/main.kt`)
- ❌ **Base Salary Calculation Bug**: Lines 212–215 added `(dailyRate / 8) * getRateNoOT()` to regular days with 0 overtime, awarding 562.50 PHP instead of 500.00 PHP for standard 8-hour days.
  - ✅ **Fixed**: Base pay correctly computes `dailyRate * multiplier`.
- ❌ **Absence Compensation Bug**: Unworked normal days still defaulted to 500.00 PHP.
  - ✅ **Fixed**: Absent normal days now evaluate to `0.00 PHP`.
- ❌ **Rate Key Incompatibilities**: Missing lookups for `rhr` and `snwh`.
  - ✅ **Fixed**: Added complete mapping for all holiday and rest day combinations.

### 3. Ruby Implementation (`src/ruby/main.rb`)
- ❌ **Off-by-One Day Indexing**: Loop called `retrieve_workday(day - 1)`, while `retrieve_workday` already subtracted 1 (`@workdays[day - 1]`). For Day 1, this accessed `@workdays[-1]` (Day 7).
  - ✅ **Fixed**: Passed 1-based `day` to `retrieve_workday(day)`.
- ❌ **Boundary Flaw at 22:00**: Shifts ending exactly at `2200` failed both `< 2200` and `> 2200` checks, omitting 4 hours of valid overtime.
  - ✅ **Fixed**: Adjusted boundary to `>= 2200`.
- ❌ **Rate Multiplier Typo**: Rest Day Night Shift rate was listed as `1.869` instead of `1.859`.
  - ✅ **Fixed**: Corrected rate to `1.859`.

---

## 📂 Project Folder Hierarchy

The project is structured according to an industry-standard, clean, and modular folder layout:

```text
WeeklyPay-CSADPRG/
│
├── docs/                                   # Project documentation & academic specifications
│   ├── specs/                              # Course MCO PDF specifications
│   │   └── CSADPRG MCO Specifications 2023.pdf
│   └── samples/                            # Input & output reference transcripts
│       └── input-output.txt
│
├── src/                                    # Source code segregated by language
│   ├── go/                                 # Go implementation
│   │   ├── main.go
│   │   └── go.mod
│   ├── kotlin/                             # Kotlin implementation
│   │   └── main.kt
│   ├── ruby/                               # Ruby implementation
│   │   └── main.rb
│   └── r/                                  # R implementation
│       └── main.R
│
├── tests/                                  # Verification test suites
│   └── verify_payroll.py                   # Automated rule & calculation validator
│
├── .gitignore                              # Excludes binary builds, runner files, and logs
└── README.md                               # Comprehensive system documentation
```

---

## 🚀 How to Run

### Go
```bash
cd src/go
go run main.go
```

### Kotlin
```bash
cd src/kotlin
kotlinc main.kt -include-runtime -d payroll.jar
java -jar payroll.jar
```

### Ruby
```bash
cd src/ruby
ruby main.rb
```

### R
```bash
cd src/r
Rscript main.R
```

---

## 🧪 Automated Verification Tests

An automated test script is provided in `tests/verify_payroll.py` to validate business rules and mathematical formulas across shifts and day classifications:

```bash
python tests/verify_payroll.py
```

Expected output:
```text
Running Weekly Payroll System verification suite...
PASS: test_standard_workday
PASS: test_day_overtime
PASS: test_night_shift_overtime
PASS: test_rest_day_worked
PASS: test_regular_holiday
PASS: test_absence
PASS: test_weekly_summary_sample

All 7 test suites passed successfully!
```

---

## 📋 Sample Input & Output

```text
Payroll Menu
1. Generate Pay Roll
2. Update Work Hours / Settings
3. Exit
Select Option: 1

---------------------------------
Generating Pay Roll....
---------------------------------
Enter Employee Name: Yesha
---------------------------------
DAY 1 (if absent Enter 0900)
Enter OUT Time: 1800
Salary for the day: 500.00
---------------------------------
DAY 2 (if absent Enter 0900)
Enter OUT Time: 1800
Salary for the day: 500.00
---------------------------------
DAY 3 (if absent Enter 0900)
Enter OUT Time: 1800
Salary for the day: 500.00
---------------------------------
DAY 4 (if absent Enter 0900)
Enter OUT Time: 1800
Salary for the day: 500.00
---------------------------------
DAY 5 (if absent Enter 0900)
Enter OUT Time: 1800
Salary for the day: 500.00
---------------------------------
DAY 6 (REST DAY)
(if absent Enter 0900)
Enter OUT Time: 0900
Salary for the day: 0.00
---------------------------------
DAY 7 (REST DAY)
(if absent Enter 0900)
Enter OUT Time: 0900
Salary for the day: 0.00

---------------------------------
	Yesha's Weekly Payroll
Number of (Regular) Days Present:             5
Number of (Rest) Days Present:                0
Total Hours Overtime (Night Shift Overtime):  0 (0)
--------------------------------------------------------
Total Salary for the Week:                    2,500.00
--------------------------------------------------------
```
