/**
 * WeeklyPay-CSADPRG Web Frontend Logic
 * Computes weekly payroll adhering to Philippine Labor Standards & CSADPRG specs.
 */

const RATE_MATRIX = {
  "Normal Day": { base: 1.00, dayOt: 1.25, nightOt: 1.375 },
  "Rest Day": { base: 1.30, dayOt: 1.69, nightOt: 1.859 },
  "SNWH": { base: 1.30, dayOt: 1.69, nightOt: 1.859 },
  "SNWHR": { base: 1.50, dayOt: 1.95, nightOt: 2.145 },
  "RH": { base: 2.00, dayOt: 2.60, nightOt: 2.860 },
  "RHR": { base: 2.60, dayOt: 3.38, nightOt: 3.718 }
};

const DAY_NAMES = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];

// Initial default week configuration
let weekData = [
  { day: 1, name: "Monday", inTime: "0900", outTime: "1800", type: "Normal Day" },
  { day: 2, name: "Tuesday", inTime: "0900", outTime: "1800", type: "Normal Day" },
  { day: 3, name: "Wednesday", inTime: "0900", outTime: "1800", type: "Normal Day" },
  { day: 4, name: "Thursday", inTime: "0900", outTime: "1800", type: "Normal Day" },
  { day: 5, name: "Friday", inTime: "0900", outTime: "1800", type: "Normal Day" },
  { day: 6, name: "Saturday", inTime: "0900", outTime: "0900", type: "Rest Day" },
  { day: 7, name: "Sunday", inTime: "0900", outTime: "0900", type: "Rest Day" }
];

function parseMilitaryMinutes(timeStr) {
  const clean = (timeStr || "").padStart(4, "0");
  const hours = parseInt(clean.substring(0, 2), 10) || 0;
  const mins = parseInt(clean.substring(2, 4), 10) || 0;
  return hours * 60 + mins;
}

function computeDay(dailySalary, dayItem) {
  const hourlyRate = dailySalary / 8.0;
  const inM = parseMilitaryMinutes(dayItem.inTime);
  let outM = parseMilitaryMinutes(dayItem.outTime);

  // Absence check
  if (dayItem.inTime === dayItem.outTime) {
    const isRest = dayItem.type === "Rest Day" || dayItem.day >= 6;
    return {
      workHours: 0,
      dayOt: 0,
      nightOt: 0,
      basePay: isRest ? dailySalary : 0.0,
      otPay: 0.0,
      salary: isRest ? dailySalary : 0.0,
      isPresent: false
    };
  }

  if (outM < inM) {
    outM += 24 * 60; // Next-day transition
  }

  const span = outM - inM;
  const workedM = Math.max(0, span - 60); // 1-hour unpaid meal break
  const workedHours = Math.floor(workedM / 60);

  const totalOt = Math.max(0, workedHours - 8);
  const dayOt = Math.min(4, totalOt);
  const nightOt = Math.max(0, totalOt - 4);

  const rates = RATE_MATRIX[dayItem.type] || RATE_MATRIX["Normal Day"];
  const basePay = dailySalary * rates.base;
  const dayOtPay = dayOt * hourlyRate * rates.dayOt;
  const nightOtPay = nightOt * hourlyRate * rates.nightOt;
  const totalPay = basePay + dayOtPay + nightOtPay;

  return {
    workHours: workedHours,
    dayOt,
    nightOt,
    basePay,
    otPay: dayOtPay + nightOtPay,
    salary: totalPay,
    isPresent: true
  };
}

function renderTable() {
  const tbody = document.getElementById("days-table-body");
  const dailyRate = parseFloat(document.getElementById("daily-rate-input").value) || 500.0;
  tbody.innerHTML = "";

  let totalSalary = 0;
  let regPresent = 0;
  let restPresent = 0;
  let totalDayOt = 0;
  let totalNightOt = 0;
  let subtotalBase = 0;
  let subtotalOt = 0;

  weekData.forEach((item, index) => {
    const res = computeDay(dailyRate, item);
    totalSalary += res.salary;
    subtotalBase += res.basePay;
    subtotalOt += res.otPay;
    totalDayOt += res.dayOt;
    totalNightOt += res.nightOt;

    if (res.isPresent) {
      if (item.type === "Rest Day" || item.day >= 6) {
        restPresent++;
      } else {
        regPresent++;
      }
    }

    const tr = document.createElement("tr");

    tr.innerHTML = `
      <td>
        <div class="day-badge">
          Day ${item.day}
          <span class="day-tag">${item.name}</span>
        </div>
      </td>
      <td>
        <select class="select-daytype" data-index="${index}">
          <option value="Normal Day" ${item.type === "Normal Day" ? "selected" : ""}>Normal Day (1.00x)</option>
          <option value="Rest Day" ${item.type === "Rest Day" ? "selected" : ""}>Rest Day (1.30x)</option>
          <option value="SNWH" ${item.type === "SNWH" ? "selected" : ""}>Special Non-Working (1.30x)</option>
          <option value="SNWHR" ${item.type === "SNWHR" ? "selected" : ""}>Special Non-Working & Rest (1.50x)</option>
          <option value="RH" ${item.type === "RH" ? "selected" : ""}>Regular Holiday (2.00x)</option>
          <option value="RHR" ${item.type === "RHR" ? "selected" : ""}>Regular Holiday & Rest (2.60x)</option>
        </select>
      </td>
      <td>
        <input type="text" maxlength="4" class="time-input" data-field="inTime" data-index="${index}" value="${item.inTime}" />
      </td>
      <td>
        <input type="text" maxlength="4" class="time-input" data-field="outTime" data-index="${index}" value="${item.outTime}" />
      </td>
      <td class="mono-cell">${res.workHours} hrs</td>
      <td class="mono-cell">${res.dayOt + res.nightOt} (${res.nightOt})</td>
      <td class="pay-badge">₱${res.salary.toFixed(2)}</td>
    `;

    tbody.appendChild(tr);
  });

  // Update Summary DOM
  document.getElementById("total-weekly-pay").innerText = `₱${totalSalary.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  document.getElementById("stat-reg-days").innerText = regPresent;
  document.getElementById("stat-rest-days").innerText = restPresent;
  document.getElementById("stat-day-ot").innerText = `${totalDayOt} hrs`;
  document.getElementById("stat-night-ot").innerText = `${totalNightOt} hrs`;
  document.getElementById("hourly-rate-disp").innerText = `₱${(dailyRate / 8.0).toFixed(2)} / hr`;
  document.getElementById("total-ot-disp").innerText = `${totalDayOt + totalNightOt} (${totalNightOt}) hrs`;
  document.getElementById("base-pay-subtotal").innerText = `₱${subtotalBase.toFixed(2)}`;
  document.getElementById("ot-pay-subtotal").innerText = `₱${subtotalOt.toFixed(2)}`;
}

// Event Listeners
document.addEventListener("DOMContentLoaded", () => {
  renderTable();

  // Listen to input changes
  document.getElementById("timesheet-table").addEventListener("change", (e) => {
    const target = e.target;
    const index = target.getAttribute("data-index");
    if (index !== null) {
      if (target.classList.contains("select-daytype")) {
        weekData[index].type = target.value;
      } else if (target.hasAttribute("data-field")) {
        const field = target.getAttribute("data-field");
        let val = target.value.trim().padStart(4, "0");
        weekData[index][field] = val;
      }
      renderTable();
    }
  });

  document.getElementById("daily-rate-input").addEventListener("input", renderTable);

  // Preset Buttons
  document.getElementById("btn-load-spec-sample").addEventListener("click", () => {
    weekData = [
      { day: 1, name: "Monday", inTime: "0900", outTime: "1800", type: "Normal Day" },
      { day: 2, name: "Tuesday", inTime: "0900", outTime: "1800", type: "Normal Day" },
      { day: 3, name: "Wednesday", inTime: "0900", outTime: "1800", type: "Normal Day" },
      { day: 4, name: "Thursday", inTime: "0900", outTime: "1800", type: "Normal Day" },
      { day: 5, name: "Friday", inTime: "0900", outTime: "1800", type: "Normal Day" },
      { day: 6, name: "Saturday", inTime: "0900", outTime: "0900", type: "Rest Day" },
      { day: 7, name: "Sunday", inTime: "0900", outTime: "0900", type: "Rest Day" }
    ];
    renderTable();
  });

  document.getElementById("btn-reset").addEventListener("click", () => {
    weekData.forEach((d) => {
      d.inTime = "0900";
      d.outTime = d.day >= 6 ? "0900" : "1800";
      d.type = d.day >= 6 ? "Rest Day" : "Normal Day";
    });
    renderTable();
  });

  // Export Summary
  document.getElementById("btn-export").addEventListener("click", () => {
    const emp = document.getElementById("employee-name").value || "Employee";
    const total = document.getElementById("total-weekly-pay").innerText;
    const reg = document.getElementById("stat-reg-days").innerText;
    const rest = document.getElementById("stat-rest-days").innerText;
    const ot = document.getElementById("total-ot-disp").innerText;

    const report = 
`=========================================
WEEKLY PAYROLL REPORT: ${emp}
=========================================
Number of (Regular) Days Present: ${reg}
Number of (Rest) Days Present:    ${rest}
Total Overtime Hours:             ${ot}
-----------------------------------------
Total Salary for the Week:        ${total}
=========================================
Generated by WeeklyPay-CSADPRG`;

    navigator.clipboard.writeText(report).then(() => {
      alert("Payroll summary report copied to clipboard!");
    }).catch(() => {
      alert(report);
    });
  });
});
