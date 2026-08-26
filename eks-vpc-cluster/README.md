# eks-vpc-cluster

Terraform-проєкт, який піднімає базову інфраструктуру для ML-сервісів в AWS: VPC та EKS-кластер з двома node group-ами.

## Структура

```
eks-vpc-cluster/
├── vpc/    — VPC, public/private підмережі, NAT gateway
└── eks/    — EKS-кластер і node group-и (бере дані про VPC через terraform_remote_state)
```

## Вимоги

- Terraform >= 1.5
- AWS CLI з налаштованим профілем (`aws configure --profile goit-terraform`)
- kubectl
- S3-бакет `mlops-tfstate-goit-512523811086` та DynamoDB-таблиця `mlops-tfstate-lock` — вони вже створені й використовуються як backend для стейту та locking

## Запуск

Спочатку піднімаємо мережу:

```bash
cd vpc
terraform init
terraform apply
```

І тільки після того, як VPC успішно створився, переходимо до кластера — він читає id підмереж з state VPC:

```bash
cd ../eks
terraform init
terraform apply
```

## Перевірка

Підключаємось до кластера і дивимось на ноди:

```bash
aws eks --region us-east-1 update-kubeconfig --name goit-mlops --profile goit-terraform
kubectl get nodes
```

Має з'явитись по одній ноді з кожної групи (`cpu-nodes`, `gpu-nodes`) у статусі `Ready`.

## Node group-и

- **cpu-nodes** — ноди під звичайні CPU-навантаження.
- **gpu-nodes** — окрема group під GPU/workload-навантаження, з taint для ізоляції.

## Видалення ресурсів

Порядок має значення — EKS залежить від VPC, тому видаляємо спочатку його:

```bash
cd eks
terraform destroy

cd ../vpc
terraform destroy
```
