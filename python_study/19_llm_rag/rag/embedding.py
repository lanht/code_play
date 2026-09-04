from ast import mod
from openai import OpenAI

client = OpenAI()

def creat_embedding(text: str):
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return (response.data[0].embedding)