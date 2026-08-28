# mlops-train-automation

Автоматизація тренування ML-моделей через AWS Step Functions і GitLab CI. Спрощений workflow із двох кроків: валідація даних (`ValidateData`) і логування результатів (`LogMetrics`), обидва — окремі Lambda-функції на Python. GitLab CI автоматично запускає Step Function після кожного `push`.

## Структура

```
mlops-train-automation/
├── terraform/
│   ├── main.tf          # IAM-ролі, Lambda-функції, Step Function
│   ├── data.tf
│   ├── terraform.tf     # backend + provider
│   ├── variables.tf
│   └── lambda/
│       ├── validate.py
│       ├── log_metrics.py
│       ├── validate.zip
│       └── log_metrics.zip
├── .gitlab-ci.yml
└── README.md
```

## Вимоги

- Terraform >= 1.5
- AWS CLI з налаштованим профілем (`aws configure --profile goit-terraform`)
- S3-бакет `mlops-tfstate-goit-512523811086` та DynamoDB-таблиця `mlops-tfstate-lock` — вже створені, використовуються як backend для стейту

## Створення Lambda-архівів

Після зміни `validate.py` або `log_metrics.py` архіви потрібно перезібрати:

```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
```

(на Windows без `zip` — `Compress-Archive -Path validate.py -DestinationPath validate.zip -Force`)

## Розгортання інфраструктури

```bash
cd terraform
terraform init
terraform apply
```

Створює: IAM-роль для Lambda (`AWSLambdaBasicExecutionRole`), IAM-роль для Step Function (право `lambda:InvokeFunction` на обидві функції), дві Lambda-функції та Step Function `mlops-train-automation-pipeline` зі структурою `ValidateData → LogMetrics`.

Після `apply` ARN Step Function доступний в output:

```bash
terraform output state_machine_arn
```

## Ручний запуск Step Function

Через AWS CLI:

```bash
aws stepfunctions start-execution \
  --state-machine-arn "$(terraform -chdir=terraform output -raw state_machine_arn)" \
  --name "manual-$(date +%s)" \
  --input '{"source": "manual-test", "commit": "test123"}' \
  --profile goit-terraform --region us-east-1
```

Перевірка результату:

```bash
aws stepfunctions describe-execution --execution-arn <execution-ARN> --profile goit-terraform --region us-east-1
```

Або візуально — в [AWS Console → Step Functions](https://us-east-1.console.aws.amazon.com/states/home?region=us-east-1#/statemachines), відкрити state machine, обрати execution і подивитись граф `ValidateData → LogMetrics` з підсвіченими пройденими кроками.

## GitLab CI

`.gitlab-ci.yml` містить job `train-model` (stage `train`), який запускається на подію `push` (`rules: if $CI_PIPELINE_SOURCE == "push"`) і викликає:

```bash
aws stepfunctions start-execution \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --name "train-$(date +%s)" \
  --input "{\"source\": \"gitlab-ci\", \"commit\": \"$CI_COMMIT_SHORT_SHA\"}"
```

Job виконується в офіційному образі `amazon/aws-cli:2.15.0`. AWS-креди підтягуються зі змінних CI/CD (нижче) — окремої аутентифікації в скрипті не потрібно, AWS CLI читає їх з середовища автоматично.

![Успішний job train-model у GitLab CI](img/19.png)

### Необхідні змінні CI/CD

Додаються в **Settings → CI/CD → Variables**:

| Key | Приклад значення | Protected | Masked |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | ✓ | ✓ |
| `AWS_SECRET_ACCESS_KEY` | `...` | ✓ | ✓ |
| `AWS_DEFAULT_REGION` | `us-east-1` | ✓ | — |
| `STATE_MACHINE_ARN` | `arn:aws:states:us-east-1:512523811086:stateMachine:mlops-train-automation-pipeline` | ✓ | — |

Якщо в GitLab-групі налаштована OIDC-інтеграція з AWS (IAM Identity Provider + Role), `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` не потрібні — CI отримує тимчасові credentials через `aws sts assume-role-with-web-identity` замість статичних ключів.

### Приклад JSON, який передається до Step Function

```json
{
  "source": "gitlab-ci",
  "commit": "a1b2c3d"
}
```

`ValidateData` повертає `{"status": "validated", "source": ..., "commit": ...}`, який автоматично стає входом для `LogMetrics` — фінальний output пайплайну:

```json
{
  "status": "logged",
  "validation_status": "validated",
  "source": "gitlab-ci",
  "commit": "a1b2c3d"
}
```

## Прибирання ресурсів

```bash
cd terraform
terraform destroy
```

S3-бакет для стейтів (`mlops-tfstate-goit-512523811086`) не видаляється — залишається для наступних запусків.
