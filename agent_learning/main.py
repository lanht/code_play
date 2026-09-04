import os

import httpx2 as httpx
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

# 指向本地 Ollama 的 OpenAI 兼容接口
# trust_env=False：绕过系统代理，否则发往 localhost 的请求会被系统 HTTP 代理拦截
client = OpenAI(
    base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1"),
    api_key="ollama",  # Ollama 不校验 key，随便填一个非空值即可
    http_client=httpx.Client(trust_env=False),
)

response = client.chat.completions.create(
    model=os.getenv("OLLAMA_MODEL", "qwen3.5:latest"),  # 本地已 pull 的模型
    messages=[
        {"role": "user", "content": "你好，请用一句话介绍什么是 AI Agent"},
    ],
)

print(response.choices[0].message.content)
