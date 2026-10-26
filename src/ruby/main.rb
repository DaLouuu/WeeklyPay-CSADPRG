=begin
********************
Course: CSADPRG (Comparative Study of Programming Languages)
Language: Ruby
Paradigm(s): Object Oriented, Functional, Procedural
Component: Weekly Payroll System
********************
=end

# CONSTANTS
HOURLY_RATE = 62.5
NON_NIGHT_SHIFT = 0
NIGHT_SHIFT = 1
NIGHT_SHIFT_TIME = [2300, 0, 100, 200, 300, 400, 500, 600]
DIFF = 1.10 # Night Shift Differential

def display_main_menu
  puts "\nWEEKLY PAYROLL SYSTEM"
  puts "-------------------------"
  puts "1. Configure Employee"
  puts "2. Generate Payroll"
  puts "3. Exit the Program"
  puts "--------------------------"
  print "Select an option: "
end

# Represents a workday with attributes for start time, end time, day type, and additional pay
class Workday
  attr_accessor :daily_wage, :start_time, :end_time, :day_type, :overtime_hours, :night_shift_hours

  def initialize(start_time = 900, end_time = 900, day_type = "Normal Day")
    @daily_wage = 500.0
    @start_time = start_time
    @end_time = end_time
    @day_type = day_type
    @overtime_hours = 0
    @night_shift_hours = 0
  end

  def calculate_additional_pay
    @overtime_hours = 0
    @night_shift_hours = 0

    return if @start_time == @end_time # Absent or no work

    # Regular schedule is 0900 to 1800 (8 hours work + 1 unpaid break)
    if (@start_time == 900 && @end_time >= 2200) || (@start_time == 900 && NIGHT_SHIFT_TIME.include?(@end_time))
      @overtime_hours = 4
    elsif @start_time == 900 && @end_time > 1800 && @end_time < 2200
      @overtime_hours = (@end_time - 1800) / 100
    end

    if NIGHT_SHIFT_TIME.include?(@end_time)
      idx = NIGHT_SHIFT_TIME.index(@end_time)
      @night_shift_hours = idx + 1
    end
  end

  def display_config
    start_str = sprintf("%04d", @start_time)
    end_str = sprintf("%04d", @end_time)

    puts "\nDAILY WAGE: #{@daily_wage}"
    puts "-------------------------------"
    puts "Start Time: #{start_str}"
    puts "End Time:   #{end_str}"
    puts "Day Type:   #{@day_type}"
    puts "Overtime Hours:     #{@overtime_hours}"
    puts "Night Shift Hours:  #{@night_shift_hours}"
  end
end

# Represents an employee with an array of workdays for each day of the week
class Worker
  attr_accessor :name

  def initialize(name)
    @name = name
    @workdays = Array.new(7) { |i| Workday.new(900, (i >= 5 ? 900 : 1700), (i >= 5 ? "Rest Day" : "Normal Day")) }
  end

  def add_workday(day, workday)
    @workdays[day - 1] = workday if day.between?(1, 7)
  end

  def retrieve_workday(day)
    @workdays[day - 1] if day.between?(1, 7)
  end
end

def find_worker(workers, name)
  workers.any? { |w| w.name.casecmp?(name) }
end

def get_worker(workers, name)
  workers.find { |w| w.name.casecmp?(name) }
end

def rest_holiday_multiplier(type)
  case type
  when "Rest Day"
    1.30
  when "SNWH", "Special Non-Working Day"
    1.30
  when "SNWH and Rest Day", "SNWHR"
    1.50
  when "RH", "Regular Holiday"
    2.00
  when "RH and Rest Day", "RHR"
    2.60
  else
    1.00
  end
end

def overtime_multiplier(type, is_shift)
  if is_shift == NON_NIGHT_SHIFT
    case type
    when "Normal Day"
      1.25
    when "Rest Day", "SNWH", "Special Non-Working Day"
      1.69
    when "SNWH and Rest Day", "SNWHR"
      1.95
    when "RH", "Regular Holiday"
      2.60
    when "RH and Rest Day", "RHR"
      3.38
    else
      1.25
    end
  else # NIGHT_SHIFT
    case type
    when "Normal Day"
      1.375
    when "Rest Day", "SNWH", "Special Non-Working Day"
      1.859
    when "SNWH and Rest Day", "SNWHR"
      2.145
    when "RH", "Regular Holiday"
      2.860
    when "RH and Rest Day", "RHR"
      3.718
    else
      1.375
    end
  end
end

# Main Program Loop
workers = []

loop do
  display_main_menu
  input = gets
  break unless input
  choice = input.chomp.to_i

  case choice
  when 1 # Configure Employee
    puts "\nCONFIGURE EMPLOYEE"
    print "Enter employee name: "
    name = gets.chomp.strip

    unless find_worker(workers, name)
      workers << Worker.new(name)
      puts "New employee '#{name}' added!"
    end

    worker = get_worker(workers, name)
    (1..7).each do |day|
      workday = worker.retrieve_workday(day)

      puts "\nModifying attributes for Day #{day} of Employee: #{worker.name}"
      puts "Current configuration:"
      workday.display_config

      print "-------------------------------\nEnter End Time (HHMM, 0900 if absent): "
      workday.end_time = gets.chomp.to_i

      if workday.end_time != 900
        print "Enter Day Type (Normal Day, Rest Day, SNWH, SNWHR, RH, RHR): "
        workday.day_type = gets.chomp.strip
      elsif day != 6 && day != 7
        workday.day_type = "Absent"
      else
        workday.day_type = "Rest Day"
      end

      workday.calculate_additional_pay
      puts "\nUpdated configuration for Day #{day}:"
      workday.display_config
    end

  when 2 # Generate Payroll
    puts "\nGENERATE PAYROLL"
    print "Enter employee name: "
    name = gets.chomp.strip

    if find_worker(workers, name)
      worker = get_worker(workers, name)
      weekly_earnings = 0.0
      regular_days_present = 0
      rest_days_present = 0
      total_ot = 0
      total_night_ot = 0

      puts "\n========================================="
      puts "Daily Breakdown for #{worker.name}:"
      puts "========================================="

      (1..7).each do |day|
        workday = worker.retrieve_workday(day)
        workday.calculate_additional_pay

        earnings = 0.0

        if workday.start_time == 900 && workday.end_time != 900
          # Worked
          base_multiplier = rest_holiday_multiplier(workday.day_type)
          earnings = workday.daily_wage * base_multiplier

          if workday.overtime_hours > 0
            earnings += workday.overtime_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, NON_NIGHT_SHIFT)
          end

          if workday.night_shift_hours > 0
            earnings += workday.night_shift_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, NIGHT_SHIFT)
          end

          if day >= 6 || workday.day_type.include?("Rest")
            rest_days_present += 1
          else
            regular_days_present += 1
          end
        elsif workday.start_time == 900 && workday.end_time == 900
          # Absent / Did not work
          if day == 6 || day == 7 || workday.day_type.include?("Rest")
            # Rest day absent receives regular daily salary per spec
            earnings = workday.daily_wage
          else
            earnings = 0.0
          end
        end

        total_ot += workday.overtime_hours + workday.night_shift_hours
        total_night_ot += workday.night_shift_hours
        weekly_earnings += earnings

        printf "Day %d (%s) - Hours OT: %d (%d) - Salary: %.2f\n",
               day, workday.day_type, workday.overtime_hours + workday.night_shift_hours, workday.night_shift_hours, earnings
      end

      puts "\n--------------------------------------------------------"
      puts "\t#{worker.name}'s Weekly Payroll"
      puts "Number of (Regular) Days Present:\t\t#{regular_days_present}"
      puts "Number of (Rest) Days Present:\t\t\t#{rest_days_present}"
      puts "Total Hours Overtime (Night Shift Overtime):\t#{total_ot} (#{total_night_ot})"
      puts "--------------------------------------------------------"
      printf "Total Salary for the Week:\t\t\t%.2f\n", weekly_earnings
      puts "--------------------------------------------------------"
    else
      puts "Employee '#{name}' not found! Please configure employee first."
    end

  when 3
    puts "Thank you for using the Weekly Payroll System. Goodbye!"
    break
  else
    puts "\nInvalid option. Please enter 1, 2, or 3."
  end
end
