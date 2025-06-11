#
#  Engine.py
#  Blackboard AI
#
#  Created by Gamitha Samarasingha on 2025-06-11.
#

from TTS.api import TTS
import os
import subprocess

def generate_audio_files(sentences):
    tts = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2")
    os.makedirs("media/audio", exist_ok=True)
    durations = []

    for i, sentence in enumerate(sentences):
        filename = f"media/audio/line_{i}.wav"
        tts.tts_to_file(text=sentence,
                       speaker="Claribel Dervla",
                       language="en",
                       file_path=filename)

        # Get duration using ffprobe
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
             "default=noprint_wrappers=1:nokey=1", filename],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        durations.append(float(result.stdout))
    
    return durations

def generate_animation(manim_code, durations):
    # Replace duration placeholders in the code
    for i, duration in enumerate(durations):
        manim_code = manim_code.replace(f'#DURATION_{i}#', str(duration))
    
    # Write the Manim code to a temporary file
    with open('temp_scene.py', 'w') as f:
        f.write(manim_code)

    # Run manim
    subprocess.run(['manim', '-pqh', 'temp_scene.py', 'NarratedScene'])
    os.remove('temp_scene.py')