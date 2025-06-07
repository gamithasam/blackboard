import argparse
import sys
import re
from TTS.api import TTS
import os
import subprocess
from manim import *

def generate_chatgpt_prompt(topic):
    prompt = f'''You are an expert in creating educational animations using Manim and narration scripting. Your task is to generate content for a tool that automatically creates narrated animations about {topic}.

## Your Response Format
Your response must follow this exact structure:

---NARRATION---
[Write 7-8 clear, concise sentences explaining the concept, one per line]

---MANIM---
[Your Manim code here]

## Narration Requirements
- Write exactly 7-8 sentences, each on its own line
- Each sentence should explain one step or aspect of [TOPIC]
- Keep sentences clear, concise, and educational
- Total narration should be 60-90 seconds when spoken
- Ensure a logical progression of ideas

## Manim Code Requirements
1. Use `class NarratedScene(Scene):` as your class name
2. Include synchronized audio with animations using:
   ```python
   self.add_sound("media/audio/line_0.wav")
   self.wait(#DURATION_0#)  # This placeholder will be replaced with the actual audio duration
3. For each line of narration, add corresponding animation(s) with matching audio placeholders
4. Use placeholder #DURATION_0#, #DURATION_1#, etc. for each audio line's wait time
5. Follow these layout and positioning best practices:
    - Group related objects using VGroup
    - Arrange objects appropriately with .arrange(DIRECTION, buff=spacing) where DIRECTION could be UP, DOWN, LEFT, RIGHT
    - Choose arrangement directions that make sense for your specific concept
    - Use .shift() for positioning rather than absolute coordinates
    - Place text with .next_to(object, DIRECTION, buff=value) to ensure proper spacing
    - For any connections between objects, use get_center() for proper alignment
    - Use appropriate stroke_width for lines to ensure readability
6. Use clear visual distinctions:
    - Use different colors for different types of objects
    - Size elements appropriately (font_size, radius) based on their importance
    - Position labels consistently relative to their objects
7. Ensure all imports are properly included at the top
8. Avoid hardcoded coordinates - position everything relative to other objects
Remember that your code will be executed exactly as written, so it must be syntactically correct and follow Manim conventions.'''

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
