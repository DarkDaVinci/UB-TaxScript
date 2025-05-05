window.addEventListener("message", function(event) {
  if (event.data.action === "open") {
    document.body.style.display = "flex";
  } else if (event.data.action === "close") {
    document.body.style.display = "none";
  }
});

function save() {
  const base = document.getElementById("baseTax").value;
  const vehicle = document.getElementById("vehicleTax").value;

  fetch(`https://${GetParentResourceName()}/saveTaxes`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ base, vehicle })
  })
  .then(res => res.json())
  .then(() => {
    document.body.style.display = "none";
  })
  .catch(err => console.error("Napaka pri shranjevanju davkov:", err));
}

function closeUI() {
  fetch(`https://${GetParentResourceName()}/close`, {
    method: "POST"
  });
  document.body.style.display = "none";
}
