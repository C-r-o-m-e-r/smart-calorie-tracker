from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.openai_service import chat_with_nutritionist

router = APIRouter()

class ChatRequest(BaseModel):
    message: str

@router.post("/")
async def chat_endpoint(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message empty")
    
    print(f"DEBUG: User sent: '{req.message}'")
    
    reply = await chat_with_nutritionist(req.message)
    
    print(f"DEBUG: AI RAW RESPONSE: '{reply}'")
    
    if reply is None or str(reply).strip() == "":
        print("DEBUG: Reply was empty! Sending fallback message.")
        reply = "Вибач, я не зміг згенерувати відповідь. Спробуй перефразувати."

    return {"reply": reply}