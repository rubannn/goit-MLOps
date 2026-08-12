"""Запускає inference на зображенні за допомогою TorchScript-моделі MobileNetV2."""

import argparse
from pathlib import Path

import torch
from PIL import Image
from torchvision.models import MobileNet_V2_Weights

MODEL_PATH = Path("model/model.pt")
TOP_K = 3


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MobileNetV2 TorchScript inference")
    parser.add_argument("image_path", type=str, help="Шлях до вхідного зображення")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    weights = MobileNet_V2_Weights.DEFAULT
    categories = weights.meta["categories"]
    preprocess = weights.transforms()

    model = torch.jit.load(str(MODEL_PATH))
    model.eval()

    image = Image.open(args.image_path).convert("RGB")
    input_tensor = preprocess(image).unsqueeze(0)

    with torch.no_grad():
        output = model(input_tensor)
        probabilities = torch.nn.functional.softmax(output[0], dim=0)

    top_probs, top_ids = torch.topk(probabilities, TOP_K)

    print(f"Top-{TOP_K} передбачення для {args.image_path}:")
    for prob, class_id in zip(top_probs, top_ids):
        class_id = class_id.item()
        print(f"  class_id={class_id:>4} | {categories[class_id]:<25} | confidence={prob.item():.4f}")


if __name__ == "__main__":
    main()
