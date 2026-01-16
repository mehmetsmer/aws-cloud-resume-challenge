# AWS Cloud Resume Challenge

Bu proje, HTML/CSS/JS ile hazirlanmis kisisel bir CV sitesidir ve tamamen AWS Serverless mimarisi uzerinde calismaktadir.

## Mimari
* **Frontend:** S3 (Hosting), CloudFront (CDN/HTTPS)
* **Backend:** API Gateway, AWS Lambda (Python), DynamoDB
* **IaC:** Terraform ile tum altyapi kodlandi.
* **CI/CD:** GitHub Actions (Yakinda eklenecek)

## Ziyaretci Sayaci
Site, DynamoDB uzerinde tutulan bir sayac kullanir ve ziyaretci IP adresine gore tekil sayim yapar.