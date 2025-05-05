let current = { interval:20, stats:{ avgPlayers:0, avgVehicles:0 } };
let pieChart = null;

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("overlay").style.display = "none";
  document.getElementById("mainMenu").style.display = "none";

  // ESC zapre
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") closeUI();
  });

  // drsniki → updateUI
  document.getElementById("baseTax").addEventListener("input", updateUI);
  document.getElementById("vehicleTax").addEventListener("input", updateUI);
});

window.addEventListener("message", event => {
  const d = event.data;
  if (d.action === "open") {
    // shrani
    current.interval = d.interval;
    current.stats    = d.stats;

    // pokaži overlay in menu
    document.getElementById("overlay").style.display = "block";
    document.getElementById("mainMenu").style.display = "flex";

    // nastavi drsnike in boxe
    document.getElementById("intVal").innerText  = d.interval;
    document.getElementById("baseTax").value     = d.baseTax;
    document.getElementById("baseVal").innerText  = d.baseTax;
    document.getElementById("vehicleTax").value  = d.vehicleTax;
    document.getElementById("vehVal").innerText   = d.vehicleTax;

    updateUI();
  }
  if (d.action === "close") {
    document.getElementById("overlay").style.display = "none";
    document.getElementById("mainMenu").style.display = "none";
  }
});

function save() {
  const b = +document.getElementById("baseTax").value;
  const v = +document.getElementById("vehicleTax").value;
  fetch(`https://${GetParentResourceName()}/saveTaxes`, {
    method:"POST",
    headers:{"Content-Type":"application/json"},
    body: JSON.stringify({ base:b, vehicle:v })
  }).catch(console.error);
}

function closeUI() {
  fetch(`https://${GetParentResourceName()}/close`, { method:"POST" })
    .then(() => {
      document.getElementById("overlay").style.display = "none";
      document.getElementById("mainMenu").style.display = "none";
    });
}

function updateUI() {
  const b = +document.getElementById("baseTax").value;
  const v = +document.getElementById("vehicleTax").value;
  document.getElementById("baseVal").innerText = b;
  document.getElementById("vehVal").innerText  = v;

  const ap = current.stats.avgPlayers;
  const av = current.stats.avgVehicles;
  const int= current.interval;

  const incBase    = ap * b;
  const incVehicle = ap * av * v;
  const total      = incBase + incVehicle;

  document.getElementById("estimateText").innerText = total.toFixed(0);

  // osveži pie chart
  const ctx = document.getElementById("pieChart").getContext("2d");
  if (pieChart) pieChart.destroy();
  pieChart = new Chart(ctx, {
    type:'pie',
    data:{
      labels:['Base','Vehicle'],
      datasets:[{ data:[incBase,incVehicle], backgroundColor:['#0af','#f55'] }]
    }
  });
}
