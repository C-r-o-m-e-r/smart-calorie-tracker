# backend/app/services/openai_service.py
import base64
import json
import os
import re
from openai import AsyncOpenAI
from app.core.config import settings

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def clean_json_string(json_string):
    """
    Cleans the string to extract valid JSON.
    Removes Markdown, finds the first '{' and last '}'.
    """
    # Remove markdown code blocks
    json_string = json_string.replace("```json", "").replace("```", "")
    
    # Find the start and end of the JSON object
    start_index = json_string.find("{")
    end_index = json_string.rfind("}")
    
    if start_index != -1 and end_index != -1:
        return json_string[start_index : end_index + 1]
    
    return json_string

async def analyze_food_image(image_path: str):
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"file not found at {image_path}")
        
    if not settings.OPENAI_API_KEY:
        raise ValueError("critical: openai_api_key is missing")

    base64_image = encode_image(image_path)

    print("DEBUG: Sending request to OpenAI...")

    # We increased the token limit to 2000 to prevent cut-off JSON
    response = await client.chat.completions.create(
        model="gpt-5-nano",
        messages=[
            {
                "role": "system",
                "content": """
                You are a professional nutritionist AI. Analyze the image.
                Return ONLY a JSON object with this exact structure:
                {
                    "name": "dish name",
                    "calories": 0,
                    "protein": 0.0,
                    "fats": 0.0,
                    "carbs": 0.0,
                    "weight_grams": 0.0,
                    "is_food": true
                }
                If it's not food, set is_food to false.
                DO NOT write any text outside the JSON.
                """
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyze this meal. JSON only."},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}"
                        }
                    }
                ],
            }
        ],
        extra_body={
            "max_completion_tokens": 2000 
        }
    )

    message = response.choices[0].message
    
    # Check for refusal
    if hasattr(message, 'refusal') and message.refusal:
        print(f"DEBUG: AI REFUSAL: {message.refusal}")
        raise ValueError(f"AI Refused: {message.refusal}")

    result_content = message.content
    print(f"DEBUG: RAW AI RESPONSE (First 100 chars): {result_content[:100]}...")

    if not result_content:
        raise ValueError("AI returned empty content.")

    try:
        # Aggressive cleaning
        cleaned_content = clean_json_string(result_content)
        return json.loads(cleaned_content)
    except json.JSONDecodeError as e:
        print(f"DEBUG: JSON PARSE ERROR: {e}")
        print(f"DEBUG: BAD CONTENT: {result_content}")
        raise ValueError(f"Failed to parse AI JSON: {e}")