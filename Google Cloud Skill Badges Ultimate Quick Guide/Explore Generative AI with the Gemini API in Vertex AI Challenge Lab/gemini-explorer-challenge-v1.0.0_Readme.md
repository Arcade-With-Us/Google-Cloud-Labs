{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "9974ac24-0b81-43eb-a8b3-5bc86d402552",
   "metadata": {
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Requirement already satisfied: google-cloud-aiplatform in /opt/conda/lib/python3.10/site-packages (1.86.0)\n",
      "Collecting google-cloud-aiplatform\n",
      "  Downloading google_cloud_aiplatform-1.89.0-py2.py3-none-any.whl.metadata (35 kB)\n",
      "Requirement already satisfied: google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1 in /opt/conda/lib/python3.10/site-packages (from google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (2.24.2)\n",
      "Requirement already satisfied: google-auth<3.0.0,>=2.14.1 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (2.38.0)\n",
      "Requirement already satisfied: proto-plus<2.0.0,>=1.22.3 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (1.26.1)\n",
      "Requirement already satisfied: protobuf!=4.21.0,!=4.21.1,!=4.21.2,!=4.21.3,!=4.21.4,!=4.21.5,<7.0.0,>=3.20.2 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (3.20.3)\n",
      "Requirement already satisfied: packaging>=14.3 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (24.2)\n",
      "Requirement already satisfied: google-cloud-storage<3.0.0,>=1.32.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (2.19.0)\n",
      "Requirement already satisfied: google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (3.31.0)\n",
      "Requirement already satisfied: google-cloud-resource-manager<3.0.0,>=1.3.3 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (1.14.2)\n",
      "Requirement already satisfied: shapely<3.0.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (2.0.7)\n",
      "Requirement already satisfied: pydantic<3 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (2.11.0)\n",
      "Requirement already satisfied: typing-extensions in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (4.13.0)\n",
      "Requirement already satisfied: docstring-parser<1 in /opt/conda/lib/python3.10/site-packages (from google-cloud-aiplatform) (0.16)\n",
      "Requirement already satisfied: googleapis-common-protos<2.0.0,>=1.56.2 in /opt/conda/lib/python3.10/site-packages (from google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (1.69.2)\n",
      "Requirement already satisfied: requests<3.0.0,>=2.18.0 in /opt/conda/lib/python3.10/site-packages (from google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (2.32.3)\n",
      "Requirement already satisfied: grpcio<2.0dev,>=1.33.2 in /opt/conda/lib/python3.10/site-packages (from google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (1.71.0)\n",
      "Requirement already satisfied: grpcio-status<2.0.dev0,>=1.33.2 in /opt/conda/lib/python3.10/site-packages (from google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (1.49.0rc1)\n",
      "Requirement already satisfied: cachetools<6.0,>=2.0.0 in /opt/conda/lib/python3.10/site-packages (from google-auth<3.0.0,>=2.14.1->google-cloud-aiplatform) (5.5.2)\n",
      "Requirement already satisfied: pyasn1-modules>=0.2.1 in /opt/conda/lib/python3.10/site-packages (from google-auth<3.0.0,>=2.14.1->google-cloud-aiplatform) (0.4.2)\n",
      "Requirement already satisfied: rsa<5,>=3.1.4 in /opt/conda/lib/python3.10/site-packages (from google-auth<3.0.0,>=2.14.1->google-cloud-aiplatform) (4.9)\n",
      "Requirement already satisfied: google-cloud-core<3.0.0,>=2.4.1 in /opt/conda/lib/python3.10/site-packages (from google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0->google-cloud-aiplatform) (2.4.3)\n",
      "Requirement already satisfied: google-resumable-media<3.0.0,>=2.0.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0->google-cloud-aiplatform) (2.7.2)\n",
      "Requirement already satisfied: python-dateutil<3.0.0,>=2.8.2 in /opt/conda/lib/python3.10/site-packages (from google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0->google-cloud-aiplatform) (2.9.0.post0)\n",
      "Requirement already satisfied: grpc-google-iam-v1<1.0.0,>=0.14.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-resource-manager<3.0.0,>=1.3.3->google-cloud-aiplatform) (0.14.2)\n",
      "Requirement already satisfied: google-crc32c<2.0dev,>=1.0 in /opt/conda/lib/python3.10/site-packages (from google-cloud-storage<3.0.0,>=1.32.0->google-cloud-aiplatform) (1.7.1)\n",
      "Requirement already satisfied: annotated-types>=0.6.0 in /opt/conda/lib/python3.10/site-packages (from pydantic<3->google-cloud-aiplatform) (0.7.0)\n",
      "Requirement already satisfied: pydantic-core==2.33.0 in /opt/conda/lib/python3.10/site-packages (from pydantic<3->google-cloud-aiplatform) (2.33.0)\n",
      "Requirement already satisfied: typing-inspection>=0.4.0 in /opt/conda/lib/python3.10/site-packages (from pydantic<3->google-cloud-aiplatform) (0.4.0)\n",
      "Requirement already satisfied: numpy<3,>=1.14 in /opt/conda/lib/python3.10/site-packages (from shapely<3.0.0->google-cloud-aiplatform) (2.1.3)\n",
      "Requirement already satisfied: pyasn1<0.7.0,>=0.6.1 in /opt/conda/lib/python3.10/site-packages (from pyasn1-modules>=0.2.1->google-auth<3.0.0,>=2.14.1->google-cloud-aiplatform) (0.6.1)\n",
      "Requirement already satisfied: six>=1.5 in /opt/conda/lib/python3.10/site-packages (from python-dateutil<3.0.0,>=2.8.2->google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0->google-cloud-aiplatform) (1.17.0)\n",
      "Requirement already satisfied: charset_normalizer<4,>=2 in /opt/conda/lib/python3.10/site-packages (from requests<3.0.0,>=2.18.0->google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (3.4.1)\n",
      "Requirement already satisfied: idna<4,>=2.5 in /opt/conda/lib/python3.10/site-packages (from requests<3.0.0,>=2.18.0->google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (3.10)\n",
      "Requirement already satisfied: urllib3<3,>=1.21.1 in /opt/conda/lib/python3.10/site-packages (from requests<3.0.0,>=2.18.0->google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (1.26.20)\n",
      "Requirement already satisfied: certifi>=2017.4.17 in /opt/conda/lib/python3.10/site-packages (from requests<3.0.0,>=2.18.0->google-api-core!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1->google-cloud-aiplatform) (2025.1.31)\n",
      "Downloading google_cloud_aiplatform-1.89.0-py2.py3-none-any.whl (7.6 MB)\n",
      "\u001b[2K   \u001b[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u001b[0m \u001b[32m7.6/7.6 MB\u001b[0m \u001b[31m40.7 MB/s\u001b[0m eta \u001b[36m0:00:00\u001b[0mta \u001b[36m0:00:01\u001b[0m\n",
      "\u001b[?25hInstalling collected packages: google-cloud-aiplatform\n",
      "\u001b[33m  WARNING: The script tb-gcp-uploader is installed in '/home/jupyter/.local/bin' which is not on PATH.\n",
      "  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.\u001b[0m\u001b[33m\n",
      "\u001b[0mSuccessfully installed google-cloud-aiplatform-1.89.0\n"
     ]
    }
   ],
   "source": [
    "# Install required python packages\n",
    "!pip3 install --upgrade --user google-cloud-aiplatform"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "1c92d0b4-d250-4a29-ae4b-5f296f14e896",
   "metadata": {
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "{'status': 'ok', 'restart': True}"
      ]
     },
     "execution_count": 2,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "# restart the kernet after libraries are loaded\n",
    "import IPython\n",
    "\n",
    "app = IPython.Application.instance()\n",
    "app.kernel.do_shutdown(True)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "23e04fd8",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Define project information\n",
    "PROJECT_ID = \"qwiklabs-gcp-00-4095e3ae7e54\"  # @param {type:\"string\"}\n",
    "LOCATION = \"us-east1\"  # @param {type:\"string\"}\n",
    "\n",
    "# Initialize Vertex AI\n",
    "import vertexai\n",
    "\n",
    "vertexai.init(project=PROJECT_ID, location=LOCATION)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "19b4c364-eba0-4c62-85b7-f7c2c25b1e9e",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 3\n",
    "# import software libraries required\n",
    "import requests\n",
    "from vertexai.generative_models import (\n",
    "    Content,\n",
    "    FunctionDeclaration,\n",
    "    GenerativeModel,\n",
    "    Part,\n",
    "    Tool,\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "2d402d35-2356-47d5-973d-b69c106087f0",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 3.1\n",
    "# use the following documentation to assist you complete this cell\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#function-calling-generation-sdk-sample\n",
    "model = GenerativeModel(\"gemini-1.5-pro-002\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "8fcef55b-2fd3-4357-b62d-c8a48d388f68",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 3.2\n",
    "# use the following documentation to assist you complete this cell\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#function-calling-generation-sdk-sample\n",
    "get_current_weather_func = FunctionDeclaration(\n",
    "    name=\"get_current_weather\",\n",
    "    description=\"Get the current weather in a given location\",\n",
    "    parameters={\n",
    "        \"type\": \"object\",\n",
    "        \"properties\": {\n",
    "            \"location\": {\n",
    "                \"type\": \"string\",\n",
    "                \"description\": \"Location\"\n",
    "            }\n",
    "        }\n",
    "    },\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "c6dcf2f0-1b02-49c3-abf1-646403ca47d5",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 3.3\n",
    "# use the following documentation to assist you complete this cell\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#function-calling-generation-sdk-sample\n",
    "weather_tool = Tool(\n",
    "    function_declarations=[get_current_weather_func],\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "5fcd435f-43e9-4775-902c-42575bd2f61f",
   "metadata": {
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "candidates {\n",
       "  content {\n",
       "    role: \"model\"\n",
       "    parts {\n",
       "      function_call {\n",
       "        name: \"get_current_weather\"\n",
       "        args {\n",
       "          fields {\n",
       "            key: \"location\"\n",
       "            value {\n",
       "              string_value: \"Boston\"\n",
       "            }\n",
       "          }\n",
       "        }\n",
       "      }\n",
       "    }\n",
       "  }\n",
       "  finish_reason: STOP\n",
       "  avg_logprobs: -1.7031977352287087e-08\n",
       "}\n",
       "usage_metadata {\n",
       "  prompt_token_count: 23\n",
       "  candidates_token_count: 7\n",
       "  total_token_count: 30\n",
       "  prompt_tokens_details {\n",
       "    modality: TEXT\n",
       "    token_count: 23\n",
       "  }\n",
       "  candidates_tokens_details {\n",
       "    modality: TEXT\n",
       "    token_count: 7\n",
       "  }\n",
       "}\n",
       "model_version: \"gemini-1.5-pro-002\"\n",
       "create_time {\n",
       "  seconds: 1744892486\n",
       "  nanos: 590191000\n",
       "}\n",
       "response_id: \"RvIAaO-CJPDtwtQPqJOE2Q4\""
      ]
     },
     "execution_count": 6,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "# Task 3.4\n",
    "# use the following documentation to assist you complete this cell\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#function-calling-generation-sdk-sample\n",
    "prompt = \"What is the weather like in Boston?\"\n",
    "\n",
    "response = model.generate_content(\n",
    "    prompt,\n",
    "    generation_config={\"temperature\": 0},\n",
    "    tools=[weather_tool],\n",
    ")\n",
    "response"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "e627baf8-cccb-467f-8ebe-cc4b3906ff33",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 4\n",
    "# Run the following cell to import required libraries \n",
    "from vertexai.generative_models import (\n",
    "    GenerationConfig,\n",
    "    Image,\n",
    "    Part,\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "3d306edd-9888-4346-beab-120009fdb630",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Task 4.1\n",
    "# Load the correct Gemini model use the following documentation to assist:\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/overview#supported-use-cases\n",
    "multimodal_model = GenerativeModel(\"gemini-1.5-pro-002\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 18,
   "id": "aed775b0-d63a-4a6a-9a55-8fe85ba0304b",
   "metadata": {
    "tags": []
   },
   "outputs": [],
   "source": [
    "import http.client\n",
    "import typing\n",
    "import urllib.request\n",
    "\n",
    "import IPython.display\n",
    "from PIL import Image as PIL_Image\n",
    "from PIL import ImageOps as PIL_ImageOps\n",
    "\n",
    "\n",
    "def display_images(\n",
    "    images: typing.Iterable[Image],\n",
    "    max_width: int = 600,\n",
    "    max_height: int = 350,\n",
    ") -> None:\n",
    "    for image in images:\n",
    "        pil_image = typing.cast(PIL_Image.Image, image._pil_image)\n",
    "        if pil_image.mode != \"RGB\":\n",
    "            # RGB is supported by all Jupyter environments (e.g. RGBA is not yet)\n",
    "            pil_image = pil_image.convert(\"RGB\")\n",
    "        image_width, image_height = pil_image.size\n",
    "        if max_width < image_width or max_height < image_height:\n",
    "            # Resize to display a smaller notebook image\n",
    "            pil_image = PIL_ImageOps.contain(pil_image, (max_width, max_height))\n",
    "        IPython.display.display(pil_image)\n",
    "\n",
    "\n",
    "def get_image_bytes_from_url(image_url: str) -> bytes:\n",
    "    with urllib.request.urlopen(image_url) as response:\n",
    "        response = typing.cast(http.client.HTTPResponse, response)\n",
    "        image_bytes = response.read()\n",
    "    return image_bytes\n",
    "\n",
    "\n",
    "def load_image_from_url(image_url: str) -> Image:\n",
    "    image_bytes = get_image_bytes_from_url(image_url)\n",
    "    return Image.from_bytes(image_bytes)\n",
    "\n",
    "\n",
    "def display_content_as_image(content: str | Image | Part) -> bool:\n",
    "    if not isinstance(content, Image):\n",
    "        return False\n",
    "    display_images([content])\n",
    "    return True\n",
    "\n",
    "\n",
    "def display_content_as_video(content: str | Image | Part) -> bool:\n",
    "    if not isinstance(content, Part):\n",
    "        return False\n",
    "    part = typing.cast(Part, content)\n",
    "    file_path = part.file_data.file_uri.removeprefix(\"gs://\")\n",
    "    video_url = f\"https://storage.googleapis.com/{file_path}\"\n",
    "    IPython.display.display(IPython.display.Video(video_url, width=600))\n",
    "    return True\n",
    "\n",
    "\n",
    "def print_multimodal_prompt(contents: list[str | Image | Part]):\n",
    "    \"\"\"\n",
    "    Given contents that would be sent to Gemini,\n",
    "    output the full multimodal prompt for ease of readability.\n",
    "    \"\"\"\n",
    "    for content in contents:\n",
    "        if display_content_as_image(content):\n",
    "            continue\n",
    "        if display_content_as_video(content):\n",
    "            continue\n",
    "        print(content)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 19,
   "id": "0c7e0a91-d216-4a48-a7de-587cb9d6782e",
   "metadata": {
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "-------Prompt--------\n",
      "\n",
      "What is shown in this video?\n",
      "Where should I go to see it?\n",
      "What are the top 5 places in the world that look like this?\n",
      "\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<video src=\"https://storage.googleapis.com/github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4\" controls  width=\"600\" >\n",
       "      Your browser does not support the <code>video</code> element.\n",
       "    </video>"
      ],
      "text/plain": [
       "<IPython.core.display.Video object>"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "-------Response--------\n"
     ]
    },
    {
     "ename": "NotFound",
     "evalue": "404 Publisher Model `projects/qwiklabs-gcp-00-4095e3ae7e54/locations/us-east1/publishers/google/models/gemini-2.5-pro-preview-03-25` not found.",
     "output_type": "error",
     "traceback": [
      "\u001b[0;31m---------------------------------------------------------------------------\u001b[0m",
      "\u001b[0;31m_MultiThreadedRendezvous\u001b[0m                  Traceback (most recent call last)",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/google/api_core/grpc_helpers.py:170\u001b[0m, in \u001b[0;36m_wrap_stream_errors.<locals>.error_remapped_callable\u001b[0;34m(*args, **kwargs)\u001b[0m\n\u001b[1;32m    169\u001b[0m     prefetch_first \u001b[38;5;241m=\u001b[39m \u001b[38;5;28mgetattr\u001b[39m(callable_, \u001b[38;5;124m\"\u001b[39m\u001b[38;5;124m_prefetch_first_result_\u001b[39m\u001b[38;5;124m\"\u001b[39m, \u001b[38;5;28;01mTrue\u001b[39;00m)\n\u001b[0;32m--> 170\u001b[0m     \u001b[38;5;28;01mreturn\u001b[39;00m \u001b[43m_StreamingResponseIterator\u001b[49m\u001b[43m(\u001b[49m\n\u001b[1;32m    171\u001b[0m \u001b[43m        \u001b[49m\u001b[43mresult\u001b[49m\u001b[43m,\u001b[49m\u001b[43m \u001b[49m\u001b[43mprefetch_first_result\u001b[49m\u001b[38;5;241;43m=\u001b[39;49m\u001b[43mprefetch_first\u001b[49m\n\u001b[1;32m    172\u001b[0m \u001b[43m    \u001b[49m\u001b[43m)\u001b[49m\n\u001b[1;32m    173\u001b[0m \u001b[38;5;28;01mexcept\u001b[39;00m grpc\u001b[38;5;241m.\u001b[39mRpcError \u001b[38;5;28;01mas\u001b[39;00m exc:\n",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/google/api_core/grpc_helpers.py:92\u001b[0m, in \u001b[0;36m_StreamingResponseIterator.__init__\u001b[0;34m(self, wrapped, prefetch_first_result)\u001b[0m\n\u001b[1;32m     91\u001b[0m     \u001b[38;5;28;01mif\u001b[39;00m prefetch_first_result:\n\u001b[0;32m---> 92\u001b[0m         \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_stored_first_result \u001b[38;5;241m=\u001b[39m \u001b[38;5;28;43mnext\u001b[39;49m\u001b[43m(\u001b[49m\u001b[38;5;28;43mself\u001b[39;49m\u001b[38;5;241;43m.\u001b[39;49m\u001b[43m_wrapped\u001b[49m\u001b[43m)\u001b[49m\n\u001b[1;32m     93\u001b[0m \u001b[38;5;28;01mexcept\u001b[39;00m \u001b[38;5;167;01mTypeError\u001b[39;00m:\n\u001b[1;32m     94\u001b[0m     \u001b[38;5;66;03m# It is possible the wrapped method isn't an iterable (a grpc.Call\u001b[39;00m\n\u001b[1;32m     95\u001b[0m     \u001b[38;5;66;03m# for instance). If this happens don't store the first result.\u001b[39;00m\n",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/grpc/_channel.py:543\u001b[0m, in \u001b[0;36m_Rendezvous.__next__\u001b[0;34m(self)\u001b[0m\n\u001b[1;32m    542\u001b[0m \u001b[38;5;28;01mdef\u001b[39;00m\u001b[38;5;250m \u001b[39m\u001b[38;5;21m__next__\u001b[39m(\u001b[38;5;28mself\u001b[39m):\n\u001b[0;32m--> 543\u001b[0m     \u001b[38;5;28;01mreturn\u001b[39;00m \u001b[38;5;28;43mself\u001b[39;49m\u001b[38;5;241;43m.\u001b[39;49m\u001b[43m_next\u001b[49m\u001b[43m(\u001b[49m\u001b[43m)\u001b[49m\n",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/grpc/_channel.py:969\u001b[0m, in \u001b[0;36m_MultiThreadedRendezvous._next\u001b[0;34m(self)\u001b[0m\n\u001b[1;32m    968\u001b[0m \u001b[38;5;28;01melif\u001b[39;00m \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_state\u001b[38;5;241m.\u001b[39mcode \u001b[38;5;129;01mis\u001b[39;00m \u001b[38;5;129;01mnot\u001b[39;00m \u001b[38;5;28;01mNone\u001b[39;00m:\n\u001b[0;32m--> 969\u001b[0m     \u001b[38;5;28;01mraise\u001b[39;00m \u001b[38;5;28mself\u001b[39m\n",
      "\u001b[0;31m_MultiThreadedRendezvous\u001b[0m: <_MultiThreadedRendezvous of RPC that terminated with:\n\tstatus = StatusCode.NOT_FOUND\n\tdetails = \"Publisher Model `projects/qwiklabs-gcp-00-4095e3ae7e54/locations/us-east1/publishers/google/models/gemini-2.5-pro-preview-03-25` not found.\"\n\tdebug_error_string = \"UNKNOWN:Error received from peer ipv4:173.194.215.95:443 {created_time:\"2025-04-17T12:27:48.610263051+00:00\", grpc_status:5, grpc_message:\"Publisher Model `projects/qwiklabs-gcp-00-4095e3ae7e54/locations/us-east1/publishers/google/models/gemini-2.5-pro-preview-03-25` not found.\"}\"\n>",
      "\nThe above exception was the direct cause of the following exception:\n",
      "\u001b[0;31mNotFound\u001b[0m                                  Traceback (most recent call last)",
      "Cell \u001b[0;32mIn[19], line 25\u001b[0m\n\u001b[1;32m     22\u001b[0m print_multimodal_prompt(contents)\n\u001b[1;32m     24\u001b[0m \u001b[38;5;28mprint\u001b[39m(\u001b[38;5;124m\"\u001b[39m\u001b[38;5;130;01m\\n\u001b[39;00m\u001b[38;5;124m-------Response--------\u001b[39m\u001b[38;5;124m\"\u001b[39m)\n\u001b[0;32m---> 25\u001b[0m \u001b[38;5;28;01mfor\u001b[39;00m response \u001b[38;5;129;01min\u001b[39;00m responses:\n\u001b[1;32m     26\u001b[0m     \u001b[38;5;28mprint\u001b[39m(response\u001b[38;5;241m.\u001b[39mtext, end\u001b[38;5;241m=\u001b[39m\u001b[38;5;124m\"\u001b[39m\u001b[38;5;124m\"\u001b[39m)\n",
      "File \u001b[0;32m~/.local/lib/python3.10/site-packages/vertexai/generative_models/_generative_models.py:902\u001b[0m, in \u001b[0;36m_GenerativeModel._generate_content_streaming\u001b[0;34m(self, contents, generation_config, safety_settings, tools, tool_config, labels)\u001b[0m\n\u001b[1;32m    875\u001b[0m \u001b[38;5;250m\u001b[39m\u001b[38;5;124;03m\"\"\"Generates content.\u001b[39;00m\n\u001b[1;32m    876\u001b[0m \n\u001b[1;32m    877\u001b[0m \u001b[38;5;124;03mArgs:\u001b[39;00m\n\u001b[0;32m   (...)\u001b[0m\n\u001b[1;32m    892\u001b[0m \u001b[38;5;124;03m    A stream of GenerationResponse objects\u001b[39;00m\n\u001b[1;32m    893\u001b[0m \u001b[38;5;124;03m\"\"\"\u001b[39;00m\n\u001b[1;32m    894\u001b[0m request \u001b[38;5;241m=\u001b[39m \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_prepare_request(\n\u001b[1;32m    895\u001b[0m     contents\u001b[38;5;241m=\u001b[39mcontents,\n\u001b[1;32m    896\u001b[0m     generation_config\u001b[38;5;241m=\u001b[39mgeneration_config,\n\u001b[0;32m   (...)\u001b[0m\n\u001b[1;32m    900\u001b[0m     labels\u001b[38;5;241m=\u001b[39mlabels,\n\u001b[1;32m    901\u001b[0m )\n\u001b[0;32m--> 902\u001b[0m response_stream \u001b[38;5;241m=\u001b[39m \u001b[38;5;28;43mself\u001b[39;49m\u001b[38;5;241;43m.\u001b[39;49m\u001b[43m_prediction_client\u001b[49m\u001b[38;5;241;43m.\u001b[39;49m\u001b[43mstream_generate_content\u001b[49m\u001b[43m(\u001b[49m\n\u001b[1;32m    903\u001b[0m \u001b[43m    \u001b[49m\u001b[43mrequest\u001b[49m\u001b[38;5;241;43m=\u001b[39;49m\u001b[43mrequest\u001b[49m\n\u001b[1;32m    904\u001b[0m \u001b[43m\u001b[49m\u001b[43m)\u001b[49m\n\u001b[1;32m    905\u001b[0m \u001b[38;5;28;01mfor\u001b[39;00m chunk \u001b[38;5;129;01min\u001b[39;00m response_stream:\n\u001b[1;32m    906\u001b[0m     \u001b[38;5;28;01myield\u001b[39;00m \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_parse_response(chunk)\n",
      "File \u001b[0;32m~/.local/lib/python3.10/site-packages/google/cloud/aiplatform_v1/services/prediction_service/client.py:2410\u001b[0m, in \u001b[0;36mPredictionServiceClient.stream_generate_content\u001b[0;34m(self, request, model, contents, retry, timeout, metadata)\u001b[0m\n\u001b[1;32m   2407\u001b[0m \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_validate_universe_domain()\n\u001b[1;32m   2409\u001b[0m \u001b[38;5;66;03m# Send the request.\u001b[39;00m\n\u001b[0;32m-> 2410\u001b[0m response \u001b[38;5;241m=\u001b[39m \u001b[43mrpc\u001b[49m\u001b[43m(\u001b[49m\n\u001b[1;32m   2411\u001b[0m \u001b[43m    \u001b[49m\u001b[43mrequest\u001b[49m\u001b[43m,\u001b[49m\n\u001b[1;32m   2412\u001b[0m \u001b[43m    \u001b[49m\u001b[43mretry\u001b[49m\u001b[38;5;241;43m=\u001b[39;49m\u001b[43mretry\u001b[49m\u001b[43m,\u001b[49m\n\u001b[1;32m   2413\u001b[0m \u001b[43m    \u001b[49m\u001b[43mtimeout\u001b[49m\u001b[38;5;241;43m=\u001b[39;49m\u001b[43mtimeout\u001b[49m\u001b[43m,\u001b[49m\n\u001b[1;32m   2414\u001b[0m \u001b[43m    \u001b[49m\u001b[43mmetadata\u001b[49m\u001b[38;5;241;43m=\u001b[39;49m\u001b[43mmetadata\u001b[49m\u001b[43m,\u001b[49m\n\u001b[1;32m   2415\u001b[0m \u001b[43m\u001b[49m\u001b[43m)\u001b[49m\n\u001b[1;32m   2417\u001b[0m \u001b[38;5;66;03m# Done; return the response.\u001b[39;00m\n\u001b[1;32m   2418\u001b[0m \u001b[38;5;28;01mreturn\u001b[39;00m response\n",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/google/api_core/gapic_v1/method.py:131\u001b[0m, in \u001b[0;36m_GapicCallable.__call__\u001b[0;34m(self, timeout, retry, compression, *args, **kwargs)\u001b[0m\n\u001b[1;32m    128\u001b[0m \u001b[38;5;28;01mif\u001b[39;00m \u001b[38;5;28mself\u001b[39m\u001b[38;5;241m.\u001b[39m_compression \u001b[38;5;129;01mis\u001b[39;00m \u001b[38;5;129;01mnot\u001b[39;00m \u001b[38;5;28;01mNone\u001b[39;00m:\n\u001b[1;32m    129\u001b[0m     kwargs[\u001b[38;5;124m\"\u001b[39m\u001b[38;5;124mcompression\u001b[39m\u001b[38;5;124m\"\u001b[39m] \u001b[38;5;241m=\u001b[39m compression\n\u001b[0;32m--> 131\u001b[0m \u001b[38;5;28;01mreturn\u001b[39;00m \u001b[43mwrapped_func\u001b[49m\u001b[43m(\u001b[49m\u001b[38;5;241;43m*\u001b[39;49m\u001b[43margs\u001b[49m\u001b[43m,\u001b[49m\u001b[43m \u001b[49m\u001b[38;5;241;43m*\u001b[39;49m\u001b[38;5;241;43m*\u001b[39;49m\u001b[43mkwargs\u001b[49m\u001b[43m)\u001b[49m\n",
      "File \u001b[0;32m/opt/conda/lib/python3.10/site-packages/google/api_core/grpc_helpers.py:174\u001b[0m, in \u001b[0;36m_wrap_stream_errors.<locals>.error_remapped_callable\u001b[0;34m(*args, **kwargs)\u001b[0m\n\u001b[1;32m    170\u001b[0m     \u001b[38;5;28;01mreturn\u001b[39;00m _StreamingResponseIterator(\n\u001b[1;32m    171\u001b[0m         result, prefetch_first_result\u001b[38;5;241m=\u001b[39mprefetch_first\n\u001b[1;32m    172\u001b[0m     )\n\u001b[1;32m    173\u001b[0m \u001b[38;5;28;01mexcept\u001b[39;00m grpc\u001b[38;5;241m.\u001b[39mRpcError \u001b[38;5;28;01mas\u001b[39;00m exc:\n\u001b[0;32m--> 174\u001b[0m     \u001b[38;5;28;01mraise\u001b[39;00m exceptions\u001b[38;5;241m.\u001b[39mfrom_grpc_error(exc) \u001b[38;5;28;01mfrom\u001b[39;00m\u001b[38;5;250m \u001b[39m\u001b[38;5;21;01mexc\u001b[39;00m\n",
      "\u001b[0;31mNotFound\u001b[0m: 404 Publisher Model `projects/qwiklabs-gcp-00-4095e3ae7e54/locations/us-east1/publishers/google/models/gemini-2.5-pro-preview-03-25` not found."
     ]
    }
   ],
   "source": [
    "# Task 3.2 Generate a video description\n",
    "# In this cell, update the prompt to ask Gemini to describe the video URL referenced.\n",
    "# You can use the documentation at the following link to assist.\n",
    "# https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/sdk-for-gemini/gemini-sdk-overview-reference#generate-content-from-video\n",
    "# \n",
    "# Video URI: gs://github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4\n",
    "# \n",
    "prompt = \"\"\"\n",
    "What is shown in this video?\n",
    "Where should I go to see it?\n",
    "What are the top 5 places in the world that look like this?\n",
    "\"\"\"\n",
    "video = Part.from_uri(\n",
    "    uri=\"gs://github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4\",\n",
    "    mime_type=\"video/mp4\",\n",
    ")\n",
    "contents = [prompt, video]\n",
    "\n",
    "responses = multimodal_model.generate_content (contents, stream=True)\n",
    "\n",
    "print(\"-------Prompt--------\")\n",
    "print_multimodal_prompt(contents)\n",
    "\n",
    "print(\"\\n-------Response--------\")\n",
    "for response in responses:\n",
    "    print(response.text, end=\"\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "aba8b2c4-dfd4-452e-bcc1-fc3df7572e0d",
   "metadata": {},
   "outputs": [],
   "source": []
  }
 ],
 "metadata": {
  "environment": {
   "kernel": "conda-base-py",
   "name": "workbench-notebooks.m129",
   "type": "gcloud",
   "uri": "us-docker.pkg.dev/deeplearning-platform-release/gcr.io/workbench-notebooks:m129"
  },
  "kernelspec": {
   "display_name": "Python 3 (ipykernel) (Local)",
   "language": "python",
   "name": "conda-base-py"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.10.16"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
