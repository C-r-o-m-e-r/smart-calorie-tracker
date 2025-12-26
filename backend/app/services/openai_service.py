# backend/app/services/openai_service.py
# Updated for Feature #16: AI Error Handling (is_food check)

import base64
import json
import os
from openai import AsyncOpenAI
from app.core.config import settings

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

async def analyze_food_image(image_path: str):
    """
    Analyzes a local image file using OpenAI Vision.
    Now checks if the image actually contains food.
    """
    try:
        if not os.path.exists(image_path):
            print(f"Error: File not found at {image_path}")
            return None
            
        base64_image = encode_image(image_path)
        
        # --- ОНОВЛЕНО: System Prompt ---
        # Ми додали вимогу 'is_food' (boolean)
        # Якщо це кіт, машина або стілець -> is_food: false
        response = await client.chat.completions.create(
            model="gpt-5-nano",
            messages=[
                {
                    "role": "system",
                    "content": """
                    You are a nutritionist AI. Analyze the food image. 
                    Return ONLY a JSON object with these keys: 
                    - name (str)
                    - calories (int)
                    - protein (float)
                    - fats (float)
                    - carbs (float)
                    - weight_grams (float)
                    - is_food (boolean) <--- IMPORTANT
                    
                    If the image is NOT food (e.g. a cat, a person, a landscape), set "is_food" to false and other values to 0 or null.
                    Do not write markdown formatting like ```json.
                    """
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Analyze this meal."},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ],
                }
            ],
            max_tokens=300,
        )

        content = response.choices[0].message.content
        clean_content = content.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_content)
        
    except Exception as e:
        print(f"AI Error: {e}")
        return None