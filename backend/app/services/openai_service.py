# backend/app/services/openai_service.py
# FINAL 2026 VERSION: Optimized for GPT-5 Nano with Vision & Reasoning

import base64
import json
import os
from openai import AsyncOpenAI
from app.core.config import settings

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

def encode_image(image_path):
    """Кодує локальне зображення у формат Base64 для передачі в AI."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

async def analyze_food_image(image_path: str):
    """
    Аналізує зображення їжі за допомогою GPT-5 Nano.
    Використовує мультимодальні можливості та Reasoning для точного підрахунку КБЖУ.
    """
    try:
        if not os.path.exists(image_path):
            print(f"Error: File not found at {image_path}")
            return None
            
        base64_image = encode_image(image_path)

        response = await client.chat.completions.create(
            model="gpt-5-nano", # Використовуємо найшвидшу модель лінійки 2026 року
            messages=[
                {
                    "role": "system",
                    "content": """
                    You are a professional nutritionist AI specialized in visual food analysis. 
                    Analyze the image and return a strict JSON object with these keys: 
                    - name (str): name of the dish.
                    - calories (int): total energy.
                    - protein (float): grams of protein.
                    - fats (float): grams of fats.
                    - carbs (float): grams of carbs.
                    - weight_grams (float): estimated total weight.
                    - is_food (boolean): MUST be true ONLY if the image contains edible food.
                    
                    If is_food is false (non-food objects, pets, or people), set all numeric values to 0 and name to 'Not food'.
                    Use your reasoning capabilities to estimate hidden ingredients in complex dishes.
                    """
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Analyze this meal for my calorie tracker."},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ],
                }
            ],
            max_tokens=500,
            response_format={"type": "json_object"} # Гарантує валідний JSON без Markdown-тегів
        )

        # Отримуємо чистий JSON результат
        result_content = response.choices[0].message.content
        return json.loads(result_content)
        
    except Exception as e:
        print(f"AI Error during GPT-5 Nano analysis: {e}")
        return None