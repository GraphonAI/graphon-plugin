# FastAPI

## The client

```python
# graphon_search.py. Only the key is a secret.
import os
import httpx

WORKSPACE_ID = "<workspace id>"
BASE = f"https://api.beta.graphon.ai/v1/workspaces/{WORKSPACE_ID}"
BUCKET_ID = os.environ["GRAPHON_BUCKET_ID"]

client = httpx.AsyncClient(
    base_url=BASE,
    headers={"authorization": f"Bearer {os.environ['GRAPHON_API_KEY']}"},
    timeout=140.0,
)


async def call(route: str, body: dict) -> dict:
    response = await client.post(f"/{route}", json=body)
    response.raise_for_status()
    return response.json()
```

The answer route usually takes seconds. It returns an answer or an error
within about 2 minutes, so the HTTP timeout must be longer than the default.

## Search and answer endpoints

```python
from fastapi import APIRouter, Depends

from .auth import current_user
from .graphon_search import BUCKET_ID, call

router = APIRouter()


@router.post("/search")
async def search(query: str, cursor: str | None = None, user=Depends(current_user)):
    body = await call(
        "search",
        {"target": BUCKET_ID, "query": query, "mode": "hybrid", "limit": 10}
        | ({"cursor": cursor} if cursor else {}),
    )
    # Graphon answers from the whole bucket. Keep this tenant's keys only.
    prefix = f"orgs/{user.org_id}/"
    results = [r for r in body["results"] if r["key"].startswith(prefix)]
    return {"results": results, "nextCursor": body["nextCursor"]}


@router.post("/ask")
async def ask(question: str, history: list[dict], user=Depends(current_user)):
    body = await call(
        "answer",
        # Oldest first, at most 32 turns. Graphon stores none of them.
        {"target": BUCKET_ID, "query": question, "history": history[-32:]},
    )
    return {
        "answer": body["answer"],
        "sources": [s for s in body["sources"] if s["cited"]],
        "warnings": body["warnings"],
    }
```

## Research

```python
@router.post("/research")
async def start_research(question: str, user=Depends(current_user)):
    body = await call("research", {"target": BUCKET_ID, "query": question})
    return {"researchId": body["research"]["id"]}
```

Then read `GET /research/<id>/events` as a server-sent event stream and send
each progress event to the browser. Read `GET /research/<id>` when a browser
rejoins. The run stays readable until its `expiresAt`. Read that field; do
not assume a number.

## Warnings are not errors

`answer` can return `null` with the warning `index_empty` or `index_failed`.
Show the warning. Do not raise an HTTP error, and do not show an empty answer.
