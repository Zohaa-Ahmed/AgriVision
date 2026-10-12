import uvicorn
from fastapi import FastAPI, File, UploadFile
import numpy as np
from io import BytesIO
from PIL import Image
import tensorflow as tf
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# 1. LOAD MODEL

MODEL_DIR = "./plant_disease_model_v2" 
try:
    MODEL = tf.saved_model.load(MODEL_DIR)
    print(" Model loaded successfully.")
except Exception as e:
    print(f" CRITICAL ERROR: Could not load model. {e}")
    exit()

# 2. LOAD LABELS
try:
    with open("labels.txt", "r") as f:
        CLASS_NAMES = [line.strip() for line in f.readlines()]
    print(f" Loaded {len(CLASS_NAMES)} classes.")
except FileNotFoundError:
    print(" ERROR: labels.txt not found. Creating dummy labels.")
    CLASS_NAMES = ["Class 0", "Class 1", "Class 2"] # Fallback

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # 1. Read Image
        image_data = await file.read()
        image = np.array(Image.open(BytesIO(image_data)).convert("RGB"))
        
        # 2. Resize to 224x224 (Matches your training)
        image = tf.image.resize(image, [224, 224])
        image = image / 255.0  # Normalize
        
        # 3. Create Batch
        img_batch = np.expand_dims(image, 0)
        
        # 4. PREDICTION (THE FIX IS HERE)
        # We use the standard 'serving_default' signature which works for 99% of .pb models
        infer = MODEL.signatures["serving_default"]
        
        # Convert numpy batch to Tensor
        input_tensor = tf.constant(img_batch, dtype=tf.float32)
        
        # Run inference
        output = infer(input_tensor)

        # 5. Extract Result safely
        # We convert the Dictionary values to a list and grab the first one (the prediction array)
        prediction_scores = list(output.values())[0].numpy()[0]
        
        predicted_index = np.argmax(prediction_scores)
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = np.max(prediction_scores)
        
        print(f"Detected: {predicted_class} ({confidence:.2f})")

        return {
            'class_name': predicted_class,
            'class_id': int(predicted_index),
            'confidence': float(confidence)
        }

    except Exception as e:
        print(f" Error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=8000)