from json import load
from re import A
from tempfile import tempdir
from turtle import st
from fastapi import FastAPI
from pydantic import BaseModel
from openai import OpenAI
from dotenv import load_dotenv
import os

app = FastAPI()

class ChatRequst(BaseModel):
    question: str
    model: str
    temperature: float

class ChatResponse(BaseModel):
    answer: str

@app.get("/")
def home() -> dict[str, str]:
    return {
        "message": "hello FastAPI"
    }

@app.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status":"ok"
    }

@app.get("/users/{name}")
def get_user(name: str) -> dict[str, str]:
    return {
        "message": f"你好，{name}"
    }

@app.get("/chat")
def chat(question: str) -> dict[str, str]:
    return {
        "question": question,
        "anwser": f"AI正在处理：{question}"
    }

@app.post("/chat")
def chat(request: ChatRequst) -> ChatResponse:
    return ChatResponse(
        answer=f"AI回答：{request.question}"
    )

load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")
print(api_key)

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)