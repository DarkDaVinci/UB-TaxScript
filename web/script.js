window.addEventListener("message", function(event) {
    if (event.data.action === "open") {
      document.body.style.display = "flex";
    }
  });
  
  function save() {
    const base = document.getElementById("baseTax").value;
    const vehicle = document.getElementById("vehicleTax").value;
    fetch(`https://${GetParentResourceName()}/saveTaxes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ base, vehicle })
    });
  }
  
  function closeUI() {
    fetch(`https://${GetParentResourceName()}/close`, {
      method: "POST",
    });
    document.body.style.display = "none";
  }
  
  document.body.style.display = "none"; 