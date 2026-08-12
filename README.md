# goit-MLOps

## Docker: збірка образів

Fat-образ (python:3.13):

```
docker build -f Dockerfile.fat -t ml-infer-fat:1.0 .
```

Slim-образ (python:3.13-slim, multi-stage):

```
docker build -f Dockerfile.slim -t ml-infer-slim:1.0 .
```

## example.jpg

Джерело зображення: [Red Panda.JPG — Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Red_Panda.JPG)