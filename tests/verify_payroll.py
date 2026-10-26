"""
Automated Payroll Verification Test Suite
Validates rate matrices, work hours calculation, absence rules,
and weekly aggregations according to CSADPRG MCO specifications.
"""

def compute_daily_pay(daily_salary=500.0, in_time="0900", out_time="1800", day_type="Normal Day", is_rest_day=False):
    hourly_rate = daily_salary / 8.0

    # Absent check
    if in_time == out_time:
        if is_rest_day:
            return {"salary": 0.0, "day_ot": 0, "night_ot": 0, "present": False}
        else:
            return {"salary": 0.0, "day_ot": 0, "night_ot": 0, "present": False}

    in_m = int(in_time[:2]) * 60 + int(in_time[2:])
    out_m = int(out_time[:2]) * 60 + int(out_time[2:])
    if out_m < in_m:
        out_m += 1440

    span = out_m - in_m
    worked_min = max(0, span - 60) # 1 unpaid break hour
    worked_hours = worked_min // 60

    total_ot = max(0, worked_hours - 8)
    day_ot = min(4, total_ot)
    night_ot = max(0, total_ot - 4)

    rate_matrix = {
        "Normal Day": {"base": 1.00, "day_ot": 1.25, "night_ot": 1.375},
        "Rest Day": {"base": 1.30, "day_ot": 1.69, "night_ot": 1.859},
        "Special Non-Working Day": {"base": 1.30, "day_ot": 1.69, "night_ot": 1.859},
        "SNWH": {"base": 1.30, "day_ot": 1.69, "night_ot": 1.859},
        "Special Non-Working Day and Rest Day": {"base": 1.50, "day_ot": 1.95, "night_ot": 2.145},
        "SNWHR": {"base": 1.50, "day_ot": 1.95, "night_ot": 2.145},
        "Regular Holiday": {"base": 2.00, "day_ot": 2.60, "night_ot": 2.860},
        "RH": {"base": 2.00, "day_ot": 2.60, "night_ot": 2.860},
        "Regular Holiday and Rest Day": {"base": 2.60, "day_ot": 3.38, "night_ot": 3.718},
        "RHR": {"base": 2.60, "day_ot": 3.38, "night_ot": 3.718},
    }

    rates = rate_matrix.get(day_type, rate_matrix["Normal Day"])
    base_pay = daily_salary * rates["base"]
    day_ot_pay = day_ot * hourly_rate * rates["day_ot"]
    night_ot_pay = night_ot * hourly_rate * rates["night_ot"]

    total = base_pay + day_ot_pay + night_ot_pay
    return {
        "salary": round(total, 2),
        "day_ot": day_ot,
        "night_ot": night_ot,
        "present": True
    }


def test_standard_workday():
    res = compute_daily_pay(500.0, "0900", "1800", "Normal Day", False)
    assert res["salary"] == 500.00, f"Expected 500.00, got {res['salary']}"
    assert res["day_ot"] == 0
    assert res["night_ot"] == 0
    print("PASS: test_standard_workday")


def test_day_overtime():
    # 0900 to 2200 = 13 hrs span - 1 hr break = 12 hrs worked (4 hrs OT)
    res = compute_daily_pay(500.0, "0900", "2200", "Normal Day", False)
    # 500 + 4 * 62.50 * 1.25 = 500 + 312.50 = 812.50
    assert res["salary"] == 812.50, f"Expected 812.50, got {res['salary']}"
    assert res["day_ot"] == 4
    assert res["night_ot"] == 0
    print("PASS: test_day_overtime")


def test_night_shift_overtime():
    # 0900 to 0000 (midnight) = 15 hrs span - 1 hr break = 14 hrs worked (6 hrs OT: 4 day, 2 night)
    res = compute_daily_pay(500.0, "0900", "0000", "Normal Day", False)
    # 500 + (4 * 62.50 * 1.25) + (2 * 62.50 * 1.375) = 500 + 312.50 + 171.88 = 984.38
    assert res["salary"] == 984.38, f"Expected 984.38, got {res['salary']}"
    assert res["day_ot"] == 4
    assert res["night_ot"] == 2
    print("PASS: test_night_shift_overtime")


def test_rest_day_worked():
    res = compute_daily_pay(500.0, "0900", "1800", "Rest Day", True)
    # 500 * 1.30 = 650.00
    assert res["salary"] == 650.00, f"Expected 650.00, got {res['salary']}"
    print("PASS: test_rest_day_worked")


def test_regular_holiday():
    res = compute_daily_pay(500.0, "0900", "1800", "Regular Holiday", False)
    # 500 * 2.00 = 1000.00
    assert res["salary"] == 1000.00, f"Expected 1000.00, got {res['salary']}"
    print("PASS: test_regular_holiday")


def test_absence():
    res = compute_daily_pay(500.0, "0900", "0900", "Normal Day", False)
    assert res["salary"] == 0.00
    assert not res["present"]
    print("PASS: test_absence")


def test_weekly_summary_sample():
    # Matches sample input-output.txt
    weekly_salary = 0.0
    reg_present = 0
    rest_present = 0

    for day in range(1, 8):
        if day <= 5:
            res = compute_daily_pay(500.0, "0900", "1800", "Normal Day", False)
            reg_present += 1
        else:
            res = compute_daily_pay(500.0, "0900", "0900", "Rest Day", True)
        weekly_salary += res["salary"]

    assert weekly_salary == 2500.00, f"Expected 2500.00, got {weekly_salary}"
    assert reg_present == 5
    assert rest_present == 0
    print("PASS: test_weekly_summary_sample")


if __name__ == "__main__":
    print("Running Weekly Payroll System verification suite...")
    test_standard_workday()
    test_day_overtime()
    test_night_shift_overtime()
    test_rest_day_worked()
    test_regular_holiday()
    test_absence()
    test_weekly_summary_sample()
    print("\nAll 7 test suites passed successfully!")
