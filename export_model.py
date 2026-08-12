"""Експортує MobileNetV2 у форматі TorchScript для CPU-inference."""

from pathlib import Path

import torch
from torchvision.models import MobileNet_V2_Weights, mobilenet_v2

MODEL_DIR = Path("model")
MODEL_PATH = MODEL_DIR / "model.pt"


def main() -> None:
    model = mobilenet_v2(weights=MobileNet_V2_Weights.DEFAULT)
    model.eval()

    rnd_input = torch.randn(1, 3, 224, 224)

    traced_model = torch.jit.trace(model, rnd_input)

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    traced_model.save(str(MODEL_PATH))

    print(f"Модель збережено у {MODEL_PATH}")


if __name__ == "__main__":
    main()
