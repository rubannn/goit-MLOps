"""Trains LogisticRegression on Iris with several hyperparameter combinations,
logs each run to MLflow, pushes accuracy/loss to Prometheus PushGateway,
and copies the best run's model into best_model/.
"""

import os
import shutil
from itertools import product

import mlflow
import mlflow.sklearn
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, log_loss
from sklearn.model_selection import train_test_split

MLFLOW_TRACKING_URI = os.environ.get("MLFLOW_TRACKING_URI", "http://localhost:5000")
PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "http://localhost:9091")
EXPERIMENT_NAME = os.environ.get("MLFLOW_EXPERIMENT_NAME", "iris-logistic-regression")
BEST_MODEL_DIR = os.environ.get("BEST_MODEL_DIR", "best_model")

C_VALUES = [0.01, 0.1, 1.0, 10.0]
MAX_ITER_VALUES = [100, 200]


def push_metrics(run_id: str, accuracy: float, loss: float) -> None:
    registry = CollectorRegistry()
    Gauge("mlflow_accuracy", "Accuracy of the trained model", registry=registry).set(accuracy)
    Gauge("mlflow_loss", "Log loss of the trained model", registry=registry).set(loss)
    push_to_gateway(
        PUSHGATEWAY_URL,
        job="train_and_push",
        grouping_key={"run_id": run_id},
        registry=registry,
    )


def train_and_log(x_train, x_test, y_train, y_test, c: float, max_iter: int):
    with mlflow.start_run() as run:
        model = LogisticRegression(C=c, max_iter=max_iter)
        model.fit(x_train, y_train)

        predictions = model.predict(x_test)
        probabilities = model.predict_proba(x_test)
        accuracy = accuracy_score(y_test, predictions)
        loss = log_loss(y_test, probabilities)

        mlflow.log_params({"C": c, "max_iter": max_iter})
        mlflow.log_metrics({"accuracy": accuracy, "loss": loss})
        mlflow.sklearn.log_model(model, name="model")

        push_metrics(run.info.run_id, accuracy, loss)

        print(f"run_id={run.info.run_id} C={c} max_iter={max_iter} accuracy={accuracy:.4f} loss={loss:.4f}")
        return run.info.run_id, accuracy


def save_best_model(run_id: str) -> None:
    if os.path.exists(BEST_MODEL_DIR):
        shutil.rmtree(BEST_MODEL_DIR)
    mlflow.artifacts.download_artifacts(
        run_id=run_id, artifact_path="model", dst_path=BEST_MODEL_DIR
    )


def main() -> None:
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)

    data = load_iris()
    x_train, x_test, y_train, y_test = train_test_split(
        data.data, data.target, test_size=0.2, random_state=42
    )

    results = []
    for c, max_iter in product(C_VALUES, MAX_ITER_VALUES):
        results.append(train_and_log(x_train, x_test, y_train, y_test, c, max_iter))

    best_run_id, best_accuracy = max(results, key=lambda r: r[1])
    print(f"Best run: run_id={best_run_id} accuracy={best_accuracy:.4f}")

    save_best_model(best_run_id)
    print(f"Best model saved to {BEST_MODEL_DIR}/")


if __name__ == "__main__":
    main()
