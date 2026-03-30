import tensorflow as tf

SAVED_MODEL_DIR = "plant_disease_model"

converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)

# Force Android-compatible ops only
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS
]

# IMPORTANT: prevent unsupported optimizations
converter.optimizations = []

# Convert
tflite_model = converter.convert()

# Save
with open("plant_disease.tflite", "wb") as f:
    f.write(tflite_model)

print(" TFLite model created successfully (Android compatible)")



# import tensorflow as tf

# converter = tf.lite.TFLiteConverter.from_saved_model("plant_disease_model")

# converter.target_spec.supported_ops = [
#     tf.lite.OpsSet.TFLITE_BUILTINS
# ]

# converter.experimental_new_converter = False

# tflite_model = converter.convert()

# with open("plant_disease.tflite", "wb") as f:
#     f.write(tflite_model)

# print("Android-compatible TFLite model created")





# import tensorflow as tf

# converter = tf.lite.TFLiteConverter.from_saved_model("plant_disease_model")

# # Optimization for mobile
# converter.optimizations = [tf.lite.Optimize.DEFAULT]

# tflite_model = converter.convert()

# with open("plant_disease.tflite", "wb") as f:
#     f.write(tflite_model)

# print("TFLite model created successfully.")
