# materials/input

Drop transcript files here before running the transcript-guide agent.

## Naming Convention

```
<topic-slug>_transcript.txt      ← YouTube / lecture transcript
<topic-slug>_meeting.txt         ← Meeting recording transcript
<topic-slug>_podcast.txt         ← Podcast transcript
```

## Default File

The agent always reads `materials/transcripts/transcript.txt` unless you specify a path.  
To use a file from this folder, invoke:

```
@transcript-guide topic: <topic> transcript: materials/input/<filename>.txt
```

## Supported Formats

- Plain `.txt` — one long line or one sentence per line
- Timestamped YouTube transcripts (e.g. `0:00 Introduction...`)
- Meeting transcripts with speaker labels (e.g. `[Speaker 1]: ...`)
