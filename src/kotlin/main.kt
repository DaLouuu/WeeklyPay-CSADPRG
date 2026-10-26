import java.util.Calendar

class Payroll {
    val dailyRate = 500.00
    val inTime = "0900"
    var outTime = "1700" // 0900 by default (absent/rest)
    var dayType = "Normal" // Normal by default
    var overTimeHours = "0 (0)" // by default
    var dDayHour = 0
    var dNightHours = 0
    var salary = 500.00
}

fun changeOutTime(payroll: Payroll, outTime: String) {
    payroll.outTime = outTime
}

fun changeDayType(payroll: Payroll, dayType: String) {
    payroll.dayType = dayType
}

fun changeOverTimeHours(payroll: Payroll, overtime: String) {
    payroll.overTimeHours = overtime
}

fun calculateOverTime(payroll: Payroll) {
    val inTimeStr = payroll.inTime
    val outTimeStr = payroll.outTime
    var othours = 0

    // Absent check
    if (inTimeStr == outTimeStr) {
        payroll.dDayHour = 0
        payroll.dNightHours = 0
        payroll.overTimeHours = "0 (0)"
        return
    }

    try {
        val inHours = inTimeStr.substring(0, 2).toInt()
        val inMinutes = inTimeStr.substring(2, 4).toInt()

        val outHours = outTimeStr.substring(0, 2).toInt()
        val outMinutes = outTimeStr.substring(2, 4).toInt()

        var inTimeMinutes = inHours * 60 + inMinutes
        var outTimeMinutes = outHours * 60 + outMinutes

        if (outTimeMinutes < inTimeMinutes) {
            outTimeMinutes += 24 * 60 // Spans next day
        }

        val minutesPassed = outTimeMinutes - inTimeMinutes
        val hoursPassed = minutesPassed / 60

        // Regular schedule is 8 hours work + 1 unpaid break hour = 9 hours
        if (hoursPassed > 9) {
            othours = hoursPassed - 9
            payroll.dDayHour = othours
            payroll.dNightHours = 0
            payroll.overTimeHours = "$othours (0)"

            // Overtime in excess of 4 hours shifts into night shift (22:00 to 06:00)
            if (othours > 4) {
                val nightShHours = othours - 4
                val dayShHours = 4
                payroll.dDayHour = dayShHours
                payroll.dNightHours = nightShHours
                payroll.overTimeHours = "$dayShHours ($nightShHours)"
            }
        } else {
            payroll.dDayHour = 0
            payroll.dNightHours = 0
            payroll.overTimeHours = "0 (0)"
        }
    } catch (e: Exception) {
        println("INVALID input. Please use HHMM format")
    }
}

fun displayWeeklyPayRoll(payrollList: Array<Payroll>) {
    var day = 1
    var totalWeeklySalary = 0.0
    var regularDaysPresent = 0
    var restDaysPresent = 0
    var totalDayOT = 0
    var totalNightOT = 0

    for (payroll in payrollList) {
        println("-------------------")
        println("Day : $day")
        println("Daily Rate : ${payroll.dailyRate}")
        println("In Time: ${payroll.inTime}")
        println("Out Time: ${payroll.outTime}")
        println("Day Type: ${payroll.dayType}")
        println("Overtime Hours (Night Hours): ${payroll.overTimeHours}")
        println("Salary: ${payroll.salary}")
        println("-------------------")

        totalWeeklySalary += payroll.salary
        totalDayOT += payroll.dDayHour
        totalNightOT += payroll.dNightHours
        if (payroll.outTime != payroll.inTime) {
            if (payroll.dayType.lowercase() == "rest" || day >= 6) {
                restDaysPresent++
            } else {
                regularDaysPresent++
            }
        }
        day++
    }

    println("=========================================")
    println("WEEKLY PAYROLL SUMMARY")
    println("Number of (Regular) Days Present: $regularDaysPresent")
    println("Number of (Rest) Days Present: $restDaysPresent")
    println("Total Overtime Hours: ${totalDayOT + totalNightOT} ($totalNightOT)")
    println("Total Salary for the Week: %.2f".format(totalWeeklySalary))
    println("=========================================")
}

fun displayInOutTime(payrollList: Array<Payroll>) {
    var day = 1
    for (payroll in payrollList) {
        println("[$day]-------------")
        println("In Time: ${payroll.inTime}")
        println("Out Time: ${payroll.outTime}")
        println("-------------------")
        day++
    }
}

fun displayDayType(payrollList: Array<Payroll>) {
    var day = 1
    for (payroll in payrollList) {
        println("[$day]-------------")
        println("Day type: ${payroll.dayType}")
        println("-------------------")
        day++
    }
}

fun getRateNoOT(dType: String): Double {
    return when (dType.lowercase()) {
        "rest" -> 1.30
        "snwd", "snwh" -> 1.30
        "snwdr", "snwhr" -> 1.50
        "rh" -> 2.00
        "rhr", "rht" -> 2.60
        else -> 1.00
    }
}

fun getOTDayRate(dType: String): Double {
    return when (dType.lowercase()) {
        "rest" -> 1.69
        "snwd", "snwh" -> 1.69
        "snwdr", "snwhr" -> 1.95
        "rh" -> 2.60
        "rhr", "rht" -> 3.38
        else -> 1.25 // Normal
    }
}

fun getOTNightRate(dType: String): Double {
    return when (dType.lowercase()) {
        "rest" -> 1.859
        "snwd", "snwh" -> 1.859
        "snwdr", "snwhr" -> 2.145
        "rh" -> 2.860
        "rhr", "rht" -> 3.718
        else -> 1.375 // Normal
    }
}

fun computeSalary(payroll: Payroll) {
    val hourlyRate = payroll.dailyRate / 8.0
    val baseMultiplier = getRateNoOT(payroll.dayType)

    // Check absence
    if (payroll.outTime == payroll.inTime) {
        if (payroll.dayType.lowercase() == "rest") {
            payroll.salary = payroll.dailyRate
        } else {
            payroll.salary = 0.0
        }
        return
    }

    val basePay = payroll.dailyRate * baseMultiplier
    val dayOTPay = payroll.dDayHour * hourlyRate * getOTDayRate(payroll.dayType)
    val nightOTPay = payroll.dNightHours * hourlyRate * getOTNightRate(payroll.dayType)

    payroll.salary = basePay + dayOTPay + nightOTPay
}

fun main() {
    println("Payroll for the week")

    val pDay1 = Payroll()
    val pDay2 = Payroll()
    val pDay3 = Payroll()
    val pDay4 = Payroll()
    val pDay5 = Payroll()
    val pDay6 = Payroll().apply {
        changeDayType(this, "Rest")
        changeOutTime(this, "0900")
        computeSalary(this)
    }
    val pDay7 = Payroll().apply {
        changeDayType(this, "Rest")
        changeOutTime(this, "0900")
        computeSalary(this)
    }

    // Default weekdays
    computeSalary(pDay1)
    computeSalary(pDay2)
    computeSalary(pDay3)
    computeSalary(pDay4)
    computeSalary(pDay5)

    val payrollArray = arrayOf(pDay1, pDay2, pDay3, pDay4, pDay5, pDay6, pDay7)
    var choice = -1

    while (choice != 4) {
        println("\nWelcome to Payroll Simulation!")
        println("Choose an action to perform:")
        println("[1] View Current Payroll")
        println("[2] Change Out Time")
        println("[3] Change Day Type")
        println("[4] Exit")
        print("Select Option: ")

        val inputString = readLine()
        choice = inputString?.toIntOrNull() ?: -1

        when (choice) {
            1 -> {
                displayWeeklyPayRoll(payrollArray)
            }
            2 -> {
                var choice1 = -1
                while (choice1 !in 1..7) {
                    displayInOutTime(payrollArray)
                    print("Pick day (1-7): ")
                    val inputChoice1 = readLine()
                    choice1 = inputChoice1?.toIntOrNull() ?: -1

                    if (choice1 !in 1..7) {
                        println("The number you inputted is invalid, please try again")
                    }
                }

                println("You picked day $choice1")
                print("Enter out time (HHMM): ")
                var inputOutTime = readLine()?.trim()
                if (inputOutTime.isNullOrEmpty()) {
                    inputOutTime = "1700"
                }

                val choosePayroll = payrollArray[choice1 - 1]
                println("Changing out time to $inputOutTime")
                changeOutTime(choosePayroll, inputOutTime)
                calculateOverTime(choosePayroll)
                computeSalary(choosePayroll)
            }
            3 -> {
                var choice1 = -1
                while (choice1 !in 1..7) {
                    displayDayType(payrollArray)
                    print("Pick day (1-7): ")
                    val inputChoice1 = readLine()
                    choice1 = inputChoice1?.toIntOrNull() ?: -1

                    if (choice1 !in 1..7) {
                        println("The number you inputted is invalid, please try again")
                    }
                }

                println("You picked day $choice1")
                print("Enter day type (Normal, Rest, SNWH, SNWHR, RH, RHR): ")
                var inputDayType = readLine()?.trim()
                if (inputDayType.isNullOrEmpty()) {
                    inputDayType = "Normal"
                }

                val choosePayroll = payrollArray[choice1 - 1]
                changeDayType(choosePayroll, inputDayType)
                computeSalary(choosePayroll)
            }
            4 -> {
                println("Now exiting the program. Goodbye!")
            }
            else -> {
                println("Invalid choice. Please choose a valid option.")
            }
        }
    }
}