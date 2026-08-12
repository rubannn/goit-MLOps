.PHONY: install export inference build-fat build-slim build run-fat run-slim

install:
	bash scripts/install_dev_tools.sh

export:
	python export_model.py

inference:
	python app/inference.py example.jpg

build-fat:
	docker build -f Dockerfile.fat -t ml-infer-fat:1.0 .

build-slim:
	docker build -f Dockerfile.slim -t ml-infer-slim:1.0 .

build: build-fat build-slim

run-fat:
	docker run --rm -v "$(shell cygpath -m "$(CURDIR)")/example.jpg:/app/example.jpg" ml-infer-fat:1.0 example.jpg

run-slim:
	docker run --rm -v "$(shell cygpath -m "$(CURDIR)")/example.jpg:/app/example.jpg" ml-infer-slim:1.0 example.jpg

clean:
	docker rmi -f ml-infer-fat:1.0 ml-infer-slim:1.0
