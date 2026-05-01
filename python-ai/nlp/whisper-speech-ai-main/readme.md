# 🎙️ OpenAI Whisper — Speech-to-Text AI

## What is Whisper?
Whisper is OpenAI'"'"'s open-source **automatic speech recognition (ASR)** model.
It can transcribe audio in 99 languages and translate to English with near-human accuracy.

## Why Learn It?
- Powers voice assistants, meeting transcribers, lecture-to-notes apps
- Runs locally — no API key needed for local model
- Integrates with LangChain, LlamaIndex for voice-input AI agents

## Model Sizes
| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | 39M | Fastest | Basic |
| base | 74M | Fast | Good |
| small | 244M | Medium | Better |
| medium | 769M | Slow | Very good |
| large | 1550M | Slowest | Best |

## Key Code
```python
import whisper

model = whisper.load_model("base")

# Transcribe audio file
result = model.transcribe("audio.mp3")
print(result["text"])

# With timestamps
result = model.transcribe("audio.mp3", word_timestamps=True)

# Translate to English
result = model.transcribe("hindi_audio.mp3", task="translate")
```

## Learning Path
1. `pip install openai-whisper`
2. Transcribe a local audio file
3. Real-time microphone transcription (PyAudio)
4. Integrate with LangChain as a voice input tool
5. Build voice-to-text note-taking app

## What to Build
- [ ] Meeting transcriber (upload MP3 → get text)
- [ ] Real-time voice command for AI chatbot
- [ ] Lecture notes generator
- [ ] Multi-language subtitle generator
- [ ] Voice-powered LangChain agent

## Related Folders
- `computer-vision/Audio-Classification-main/` — audio ML
- `agentic-ai/Complete-Langchain-Tutorials-main/` — voice agent integration