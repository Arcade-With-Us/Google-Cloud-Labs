#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

#!/usr/bin/env bash
set -e

if [ -z "${API_KEY}" ]; then
  API_KEY=$(gcloud services api-keys list --filter="displayName:*API key*" --format="value(keyString)" 2>/dev/null | head -n 1)
  if [ -z "${API_KEY}" ]; then
    API_KEY=$(gcloud alpha services api-keys list --format="value(keyString)" 2>/dev/null | head -n 1)
  fi
fi

if [ -z "${API_KEY}" ]; then
  echo "Error: API_KEY is not set and could not be detected. Run 'export API_KEY=\"...\"' and retry."
  exit 1
fi
export API_KEY

gcloud services enable speech.googleapis.com texttospeech.googleapis.com translate.googleapis.com >/dev/null 2>&1 || true

cat << 'EOF' > synthesize-text.json
{
  "input":{
    "text":"Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16 (the encoding used in WAV files)."
  },
  "voice":{
    "languageCode":"en-GB",
    "name":"en-GB-Standard-A",
    "ssmlGender":"FEMALE"
  },
  "audioConfig":{
    "audioEncoding":"MP3"
  }
}
EOF

curl -s -H "Content-Type: application/json; charset=utf-8" --data @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize?key=${API_KEY}" -o synthesize-text.txt

cat << 'EOF' > tts_decode.py
import argparse
from base64 import decodebytes
import json

def decode_tts_output(input_file, output_file):
    with open(input_file) as input_stream:
        response = json.load(input_stream)
        audio_data = response['audioContent']
        with open(output_file, "wb") as new_file:
            new_file.write(decodebytes(audio_data.encode('utf-8')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF

python3 tts_decode.py --input "synthesize-text.txt" --output "synthesize-text-audio.mp3"

cat << 'EOF' > speech_request_fr.json
{
  "config":{
    "encoding":"FLAC",
    "languageCode":"fr-FR",
    "audioChannelCount":1
  },
  "audio":{
    "uri":"gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF

cp speech_request_fr.json speech_request.json
cp speech_request_fr.json request.json

curl -s -X POST -H "Content-Type: application/json; charset=utf-8" --data @speech_request_fr.json "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" -o response.json

cp response.json speech_response.json

curl -s -X POST -H "Content-Type: application/json; charset=utf-8" -d '{"q":"これは日本語です。","target":"en"}' "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" -o translation_response.txt

cp translation_response.txt translated_response.txt

curl -s -X POST -H "Content-Type: application/json; charset=utf-8" -d '{"q":"Este%é%japonês."}' "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" -o detection_response.txt

cp detection_response.txt detected_response.txt

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
