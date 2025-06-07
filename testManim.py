from manim import *

class TestScene(Scene):
    def construct(self):
        text = Text("Hello, Gamitha!")
        self.play(Write(text))
        self.wait(1)