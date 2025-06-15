#
#  Engine.py
#  Blackboard AI
#
#  Created by Gamitha Samarasingha on 2025-06-11.
#

from TTS.api import TTS
import os
import subprocess
import sys
import io
import time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def generate_audio_files(sentences):
    tts = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2")
    os.makedirs("/Users/gamitha/Documents/Blackboard/media/audio", exist_ok=True)
    durations = []

    for i, sentence in enumerate(sentences):
        filename = f"/Users/gamitha/Documents/Blackboard/media/audio/line_{i}.wav"
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
    
    scene_name = "NarratedScene"
    temp_scene_path = "/Users/gamitha/Documents/Blackboard/temp_scene.py"
    media_dir = "/Users/gamitha/Documents/Blackboard"
    quality = "h"  # high quality
    output_folder = os.path.join(media_dir, "media", "videos", "temp_scene", quality)
    
    with open(temp_scene_path, 'w', encoding="utf-8") as f:
        f.write(manim_code)
        
    subprocess.run([
        'manim',
        f'-q{quality}',
        'temp_scene.py',
        scene_name
    ], cwd=media_dir)
    
    os.remove(temp_scene_path)
    
    # Wait briefly to ensure the file system has flushed the output
    time.sleep(0.5)

    # Look for the most recently generated video file
    return os.path.join(media_dir, "media", "videos", "temp_scene", quality, f"{scene_name}.mp4")
