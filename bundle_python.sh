#!/bin/bash

# Script to bundle Python and dependencies into macOS app
APP_NAME="Blackboard AI"
APP_PATH="Blackboard AI/Blackboard AI.app"
PYTHON_VERSION="3.11"

echo "Creating standalone macOS app bundle..."

# Create app bundle structure if it doesn't exist
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
mkdir -p "$APP_PATH/Contents/Frameworks"

# Use existing virtual environment instead of Python.framework
VENV_PATH="venv"
PYTHON_ENV_DEST="$APP_PATH/Contents/Resources/python-env"

if [ ! -d "$PYTHON_ENV_DEST" ]; then
    echo "Copying virtual environment to app bundle..."
    
    if [ -d "$VENV_PATH" ]; then
        echo "Found virtual environment at $VENV_PATH"
        
        # Copy the entire virtual environment
        cp -R "$VENV_PATH" "$PYTHON_ENV_DEST"
        
        # Make sure Python executables are executable
        chmod +x "$PYTHON_ENV_DEST/bin/python"*
        
        echo "Virtual environment copied successfully!"
    else
        echo "Error: Virtual environment not found at $VENV_PATH"
        echo "Please create a virtual environment first:"
        echo "  python3 -m venv venv"
        echo "  source venv/bin/activate"
        echo "  pip install -r requirements.txt"
        exit 1
    fi
fi

# Use the embedded Python from copied virtual environment
EMBEDDED_PYTHON="$PYTHON_ENV_DEST/bin/python3"

if [ -f "$EMBEDDED_PYTHON" ]; then
    echo "Installing Python dependencies..."
    "$EMBEDDED_PYTHON" -m pip install --upgrade pip
    "$EMBEDDED_PYTHON" -m pip install -r requirements.txt
    
    # Copy your Python scripts
    cp "Blackboard AI/Blackboard AI/Engine.py" "$APP_PATH/Contents/Resources/"
    cp *.py "$APP_PATH/Contents/Resources/" 2>/dev/null || true
    
    # Copy required external tools
    echo "Copying external tools..."
    mkdir -p "$APP_PATH/Contents/Resources/bin"
    
    # Copy ffprobe if available
    if command -v ffprobe >/dev/null 2>&1; then
        cp "$(which ffprobe)" "$APP_PATH/Contents/Resources/bin/"
        echo "Copied ffprobe"
    else
        echo "Warning: ffprobe not found. Audio duration detection may not work."
    fi
    
    # Copy ffmpeg if available (manim might need it)
    if command -v ffmpeg >/dev/null 2>&1; then
        cp "$(which ffmpeg)" "$APP_PATH/Contents/Resources/bin/"
        echo "Copied ffmpeg"
    fi
else
    echo "Error: Embedded Python not found at $EMBEDDED_PYTHON"
    exit 1
fi

echo "Python framework and dependencies bundled successfully!"
