import tensorflow as tf

dataset_dir = "PlantVillage"  # change if your folder has a different name

train_ds = tf.keras.utils.image_dataset_from_directory(
    dataset_dir,
    validation_split=0.2,
    subset="training",
    seed=123,
    image_size=(224, 224),
    batch_size=32
)

class_names = train_ds.class_names

with open("labels.txt", "w") as f:
    for name in class_names:
        f.write(name + "\n")

print("labels.txt created successfully")
print(class_names)
