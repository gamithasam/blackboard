script = """
The Pythagorean Theorem is a fundamental principle in geometry.
It applies only to right-angled triangles.
According to the theorem, the square of the hypotenuse is equal to the sum of the squares of the other two sides.
Let's draw a right triangle with side lengths 3, 4, and 5.
Now, we build a square on each side of the triangle.
Observe that the area of the square on the hypotenuse is equal to the sum of the areas of the other two squares.
This confirms the Pythagorean Theorem visually.
"""

# Split the script into sentences manually to avoid nltk dependency issues
import re

def simple_sentence_split(text):
    # Simple sentence splitting on periods, exclamation marks, and question marks
    sentences = re.split(r'[.!?]+', text.strip())
    # Remove empty strings and strip whitespace
    sentences = [s.strip() for s in sentences if s.strip()]
    return sentences

sentences = simple_sentence_split(script)

# Generate audio files for each sentence
from TTS.api import TTS
import os

tts = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2")

os.makedirs("media/audio", exist_ok=True)
durations = []

for i, sentence in enumerate(sentences):
    filename = f"media/audio/line_{i}.wav"
    tts.tts_to_file(text=sentence, speaker="Claribel Dervla", language="en", file_path=filename)

    # Get duration using ffprobe
    import subprocess
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
         "default=noprint_wrappers=1:nokey=1", filename],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    durations.append(float(result.stdout))

# Generate video with manim
from manim import *

class NarratedScene(Scene):
    def construct(self):
        # Triangle points
        A = [0, 0, 0]
        B = [3, 0, 0]
        C = [0, 4, 0]

        # Triangle and sides
        triangle = Polygon(A, B, C, color=BLUE)
        leg1 = Line(A, B)
        leg2 = Line(A, C)
        hypotenuse = Line(B, C)

        # Squares on each side
        square_a = Square(3).rotate(PI/2).next_to(leg1, DOWN, buff=0).shift(LEFT * 0.5)
        square_b = Square(4).next_to(leg2, LEFT, buff=0).shift(DOWN * 0.5)
        from numpy import array
        square_c = Square(5).rotate(hypotenuse.get_angle()).next_to(hypotenuse, UP, buff=0)

        # Step 1
        self.add_sound("media/audio/line_0.wav")
        self.play(Write(Text("Pythagorean Theorem").scale(0.8)))
        self.wait(durations[0])

        # Step 2
        self.add_sound("media/audio/line_1.wav")
        self.play(Create(triangle))
        self.wait(durations[1])

        # Step 3
        self.add_sound("media/audio/line_2.wav")
        self.play(Indicate(hypotenuse))
        self.wait(durations[2])

        # Step 4
        self.add_sound("media/audio/line_3.wav")
        self.play(Create(leg1), Create(leg2), Create(hypotenuse))
        self.wait(durations[3])

        # Step 5
        self.add_sound("media/audio/line_4.wav")
        self.play(FadeIn(square_a), FadeIn(square_b), FadeIn(square_c))
        self.wait(durations[4])

        # Step 6
        self.add_sound("media/audio/line_5.wav")
        self.play(Indicate(square_c), Indicate(square_a), Indicate(square_b))
        self.wait(durations[5])

        # Step 7
        self.add_sound("media/audio/line_6.wav")
        self.play(FadeOut(triangle), FadeOut(square_a), FadeOut(square_b), FadeOut(square_c))
        self.wait(durations[6])