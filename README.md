# AWS Cloud Resume Challenge 

Bu proje, HTML/CSS/JS ile hazırlanmış kişisel bir CV sitesidir ve tamamen AWS Serverless mimarisi üzerinde çalışmaktadır.

## Mimari

* **Frontend:** S3 (Static Hosting) ve CloudFront (CDN/HTTPS)
* **Backend:** API Gateway, AWS Lambda (Python) ve DynamoDB
* **IaC:** Terraform ile tüm altyapı kodlandı (Infrastructure as Code).
* **CI/CD:** GitHub Actions ile Frontend otomasyonu sağlandı.

## Ziyaretçi Sayacı

Site, DynamoDB üzerinde tutulan atomik bir sayaç kullanır. Ziyaretçi IP adresine göre kontrol yaparak ("Unique Visitor") sayımı gerçekleştirir ve yapay şişirmeleri engeller.

## Proje İçeriği

* `infra/`: Terraform altyapı kodları ve Lambda fonksiyonu.
* `.github/workflows/`: Otomatik dağıtım (Deployment) kuralları.
* `index.html` & `style.css`: Site arayüzü.
* `index.js`: API ile haberleşen JavaScript kodu.