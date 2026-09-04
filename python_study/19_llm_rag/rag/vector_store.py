from gc import collect
import chromadb
from rag import embedding
import uuid 

doc_id = str(uuid.uuid4())

client = chromadb.Client()

collection = (
    client.create_collection(name="knowledge")
)

def add_document(text, vector):
    collection.add(
        documents=[text],
        embedding=[vector],
        ids=[doc_id]
    )