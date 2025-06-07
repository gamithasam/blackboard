from TTS.api import TTS

tts = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2")

tts.tts_to_file(
    text="Hello Gamitha! This is XTTS using a random speaker.",
    speaker="Ana Florence",
    language="en",
    file_path="narration.wav"
)