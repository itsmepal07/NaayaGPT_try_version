# main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from chatbot import rag_query  # import from chatbot.py in same folder
import traceback

app = FastAPI(title="Law Awareness Bot API")

# Allow requests from frontend (Flutter)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For testing; later restrict to your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "✅ Law Awareness Bot API is running!"}

@app.post("/ask")
async def ask_question(request: Request):
    try:
        data = await request.json()
        question = data.get("question", "").strip()

        if not question:
            return {"error": "Missing 'question' field."}

        answer = rag_query(question, k=3)
        return {"question": question, "answer": answer}
    except Exception as e:
        print("❌ ERROR:", traceback.format_exc())
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
