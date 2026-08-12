# goit-MLOps

Домашнє завдання №1: TorchScript-експорт моделі MobileNetV2, inference-скрипт на Python
та порівняння "важкого" і оптимізованого slim Docker-образів для inference.

## Вимоги

- Docker + Docker Compose V2
- Python >= 3.13, pip

## Команди

Перевірка середовища (Docker, Python, torch/torchvision/pillow):

```
bash scripts/install_dev_tools.sh
```

Експорт TorchScript-моделі у `model/model.pt`:

```
python export_model.py
```

Inference локально (без Docker):

```
python app/inference.py example.jpg
```

## Docker: збірка образів

Fat-образ (python:3.13):

```
docker build -f Dockerfile.fat -t ml-infer-fat:1.0 .
```

Slim-образ (python:3.13-slim, multi-stage):

```
docker build -f Dockerfile.slim -t ml-infer-slim:1.0 .
```

## Docker: запуск inference

```
docker run --rm -v "<шлях-до-проєкту>/example.jpg:/app/example.jpg" ml-infer-fat:1.0 example.jpg
docker run --rm -v "<шлях-до-проєкту>/example.jpg:/app/example.jpg" ml-infer-slim:1.0 example.jpg
```

Або через Makefile: `make build`, `make run-fat`, `make run-slim`.

## Приклад результату

```
Top-3 передбачення для example.jpg:
  class_id= 387 | lesser panda              | confidence=0.4510
  class_id= 277 | red fox                   | confidence=0.0083
  class_id= 358 | polecat                   | confidence=0.0058
```

Результат однаковий у fat- та slim-образах.

## Fat vs Slim

Slim-образ (multi-stage, `python:3.13-slim`) менший за розміром і має менше шарів,
ніж fat-образ (`python:3.13`), оскільки інструменти збірки (`build-essential` та ін.)
залишаються лише в builder-стадії й не потрапляють у фінальний образ. Детальне
порівняння — у [report.md](report.md).

## example.jpg

Джерело зображення: [Red Panda.JPG — Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Red_Panda.JPG)