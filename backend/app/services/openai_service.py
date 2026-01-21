import base64
import json
import os
import asyncio
from openai import AsyncOpenAI
from app.core.config import settings

# Initialize OpenAI client with a 60-second timeout
client = AsyncOpenAI(
    api_key=settings.OPENAI_API_KEY,
    timeout=60.0 
)

def encode_image(image_path):
    """Encodes a local image file to a base64 string."""
    try:
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        print(f"❌ [ENCODER_ERROR] Could not read file: {e}")
        return None

async def analyze_food_image(image_path: str):
    """
    Analyzes a food image using 'gpt-5-mini'.
    Increased token limit to prevent cut-off during analysis.
    """
    base64_image = encode_image(image_path)
    if not base64_image:
        return None

    print(f"🚀 [AI_VISION] Sending image analysis request to gpt-5-mini...")

    try:
        response = await client.chat.completions.create(
            model="gpt-5-mini",
            messages=[
                {
                    "role": "system",
                    "content": """
                    You are a professional nutritionist. Look at the image and provide: 
                    1. Food name. 2. Calories. 3. Protein. 4. Fats. 5. Carbs. 6. Estimated weight. 
                    Return ONLY valid JSON. keys: name, calories, protein, fats, carbs, weight_grams, is_food.
                    If it's not food, set 'is_food': false.
                    """
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Analyze this meal in detail."},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}
                        }
                    ],
                }
            ],
            # INCREASED: Giving more room for vision analysis
            extra_body={"max_completion_tokens": 2000}, 
            response_format={"type": "json_object"}
        )

        content = response.choices[0].message.content
        return json.loads(content)

    except Exception as e:
        print(f"❌ [AI_VISION_ERROR] API call failed: {str(e)}")
        return None

async def chat_with_nutritionist(message: str):
    """
    Chat with the AI nutritionist using 'gpt-5-mini'.
    Drastically increased token limit to solve 'Finish Reason: length'.
    """
    print(f"💬 [AI_CHAT] Processing request: {message[:50]}...")
    
    if not settings.OPENAI_API_KEY:
        return "System Error: No OpenAI API Key found."

    try:
        response = await client.chat.completions.create(
            model="gpt-5-mini",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are 'SmartCalorie AI', a helpful and expert nutritionist. "
                        "Keep your advice short, encouraging, and specific."
                    )
                },
                {"role": "user", "content": message}
            ],
            # INCREASED: From 1500 to 5000. 
            # Reasoning models consume tokens for thinking before outputting text.
            extra_body={"max_completion_tokens": 5000}
        )

        choice = response.choices[0]
        content = choice.message.content
        finish_reason = choice.finish_reason

        print(f"📡 [AI_DEBUG] Finish Reason: {finish_reason}")

        if content is None or content.strip() == "":
            print(f"⚠️ [AI_WARNING] Received empty content.")
            
            # Diagnostic message for logs
            if finish_reason == "length":
                print("❌ ERROR: Token limit reached during reasoning.")
                return "I was thinking too hard and ran out of space. Please try again."
                
            return "I am thinking, but I couldn't generate a text response. Please ask again."
            
        return content

    except Exception as e:
        print(f"❌ [AI_CHAT_ERROR] Exception: {str(e)}")
        return f"Service Error: {str(e)}"