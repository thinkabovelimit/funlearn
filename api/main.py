import json
import random
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Reverse Quiz API", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_FILE = Path(__file__).with_name("dataset.json")


class QuizItem(BaseModel):
    id: int
    topic: str
    answer: str
    clues: list[str]
    fun_fact: str


class SubmitRequest(BaseModel):
    item_id: int
    guess: str


class TopicAnswersResponse(BaseModel):
    topic: str
    answers: list[str]


class QuestionResponse(BaseModel):
    item_id: int
    topic: str
    clue_count: int


class HintResponse(BaseModel):
    item_id: int
    hint_index: int
    hint: str
    total_hints: int


class SubmitResponse(BaseModel):
    item_id: int
    topic: str
    correct: bool
    answer: str
    fun_fact: str


def _normalize(text: str) -> str:
    return " ".join(text.casefold().split())


def _load_items() -> list[QuizItem]:
    raw = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    items: list[QuizItem] = []
    for index, row in enumerate(raw.get("items", []), start=1):
        items.append(
            QuizItem(
                id=index,
                topic=row["topic"],
                answer=row["answer"],
                clues=row["clues"],
                fun_fact=row.get("fun_fact", ""),
            )
        )
    if not items:
        raise RuntimeError("Dataset is empty or invalid.")
    return items


ITEMS = _load_items()
TOPICS = sorted({item.topic for item in ITEMS})
ITEM_BY_ID = {item.id: item for item in ITEMS}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/topics")
def get_topics() -> dict[str, list[str]]:
    return {"topics": TOPICS}


@app.get("/topics/{topic}/answers", response_model=TopicAnswersResponse)
def get_topic_answers(topic: str) -> TopicAnswersResponse:
    filtered = [item.answer for item in ITEMS if item.topic == topic]
    if not filtered:
        raise HTTPException(status_code=404, detail="Topic not found")
    return TopicAnswersResponse(topic=topic, answers=filtered)


@app.get("/quiz/question", response_model=QuestionResponse)
def get_random_question(topic: str = Query(..., min_length=1)) -> QuestionResponse:
    filtered = [item for item in ITEMS if item.topic == topic]
    if not filtered:
        raise HTTPException(status_code=404, detail="Topic not found")
    item = random.choice(filtered)
    return QuestionResponse(item_id=item.id, topic=item.topic, clue_count=len(item.clues))


@app.get("/quiz/hint", response_model=HintResponse)
def get_hint(item_id: int = Query(..., ge=1), hint_index: int = Query(..., ge=1)) -> HintResponse:
    item = ITEM_BY_ID.get(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Question not found")
    if hint_index > len(item.clues):
        raise HTTPException(status_code=400, detail="Hint index out of range")
    return HintResponse(
        item_id=item.id,
        hint_index=hint_index,
        hint=item.clues[hint_index - 1],
        total_hints=len(item.clues),
    )


@app.post("/quiz/submit", response_model=SubmitResponse)
def submit_answer(payload: SubmitRequest) -> SubmitResponse:
    item = ITEM_BY_ID.get(payload.item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Question not found")

    correct = _normalize(payload.guess) == _normalize(item.answer)
    return SubmitResponse(
        item_id=item.id,
        topic=item.topic,
        correct=correct,
        answer=item.answer,
        fun_fact=item.fun_fact,
    )
