import kagglehub
import os

data_dir = "/app/data"
os.makedirs(data_dir, exist_ok=True)

dataset = "mysarahmadbhat/airbnb-listings-reviews"

path = kagglehub.dataset_download(dataset, target_dir=data_dir)
print("Dataset descargado en:", path)
