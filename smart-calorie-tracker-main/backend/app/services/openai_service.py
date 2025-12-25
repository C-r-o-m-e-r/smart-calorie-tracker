# backend/app/services/openai_service.py

from openai import AsyncOpenAI
from app.core.config import settings
import json

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

async def analyze_food_image(image_url: str):

    try:
        response = await client.chat.completions.create(
            model="gpt-5-nano",
            messages=[
                {
                    "role": "system",
                    "content": "You are a nutritionist AI. Analyze the food image. Return ONLY a JSON object with these keys: name (str), calories (int), protein (float), fats (float), carbs (float), weight_grams (float). Do not write markdown formatting."
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Analyze this meal."},
                        {"type": "image_url", "image_url": {"url": image_url}}
                    ],
                }
            ],
            max_tokens=300,
        )

        content = response.choices[0].message.content
        
        # parsing the response praying for valid json
        return json.loads(content)
        
    except Exception as e:
        print(f"AI Error: {e}")
        return None