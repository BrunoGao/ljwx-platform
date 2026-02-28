from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from .config import get_settings
from .db import Database
from .routes import router
from .skopeo_runner import SkopeoRunner
from .worker import WorkerService


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper(), logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )

    db = Database(settings.sqlite_path)
    skopeo = SkopeoRunner(settings)
    worker = WorkerService(db=db, skopeo=skopeo, settings=settings)

    app.state.settings = settings
    app.state.db = db
    app.state.worker = worker

    await worker.start()
    try:
        yield
    finally:
        await worker.stop()


app = FastAPI(title="Image Sync Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)
