import argparse
import sys
import re
from TTS.api import TTS
import os
import subprocess
from manim import *

def generate_chatgpt_prompt(topic):
    prompt = f'''Please help me create an educational animation about {topic}.
Generate two things:
1. A narration script split into 7-8 clear, concise sentences that explain the concept step by step.
2. A Manim Scene class that animates this explanation synced with the narration.

Format your response exactly like this:
---NARRATION---
[Your narration script here, with each sentence on a new line]

---MANIM---
[Your Manim Scene class code here]

Requirements for the narration:
- Each sentence should correspond to one step in the animation
- Keep sentences clear and concise
- Total length should be around 60-90 seconds when spoken

Requirements for the Manim code:
- Use a Scene class named "NarratedScene"
- Sync animations with audio using self.add_sound() and self.wait()
- Include placeholder comments for audio durations that will be replaced later'''

    return prompt

def extract_content(chatgpt_response):
    # Extract narration
    narration_match = re.search(r'---NARRATION---\n(.*?)\n\n---MANIM---', 
                              chatgpt_response, re.DOTALL)
    if not narration_match:
        raise ValueError("Could not find narration section in ChatGPT response")
    narration = narration_match.group(1).strip()

    # Extract Manim code
    manim_match = re.search(r'---MANIM---\n(.*)', chatgpt_response, re.DOTALL)
    if not manim_match:
        raise ValueError("Could not find Manim code section in ChatGPT response")
    manim_code = manim_match.group(1).strip()

    return narration, manim_code

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

def main():
    parser = argparse.ArgumentParser(description='Generate educational animations')
    parser.add_argument('--topic', help='Topic to generate prompt for')
    parser.add_argument('--process-response', help='Process ChatGPT response from file')
    
    args = parser.parse_args()

    if args.topic:
        prompt = generate_chatgpt_prompt(args.topic)
        print("\nCopy this prompt into ChatGPT:\n")
        print(prompt)
        print("\nAfter getting the response, save it to a file and run:")
        print(f"python {sys.argv[0]} --process-response response.txt")
    
    elif args.process_response:
        try:
            with open(args.process_response, 'r') as f:
                chatgpt_response = f.read()
            
            # Extract content
            narration, manim_code = extract_content(chatgpt_response)
            
            # Generate audio files and get durations
            sentences = [s.strip() for s in narration.split('\n') if s.strip()]
            durations = generate_audio_files(sentences)
            
            # Generate the animation
            generate_animation(manim_code, durations)
            
            print("Animation generated successfully!")
            
        except Exception as e:
            print(f"Error: {str(e)}")
            sys.exit(1)
    
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
