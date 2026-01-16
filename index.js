const counter = document.querySelector(".counter-container");

async function updateCounter() {
    try {
        // API isteği
        let response = await fetch("https://gdp5r90pv5.execute-api.eu-central-1.amazonaws.com/");
        
        // Lambda'dan dönen veriyi al
        let data = await response.json();
        
        // Ekrana yaz (data direkt sayı olmalı)
        counter.innerHTML = `Ziyaretçi Sayısı: ${data}`;
    } catch (error) {
        console.error("Sayaç hatası:", error);
        counter.innerHTML = "Ziyaretçi Sayısı: --";
    }
}

updateCounter();