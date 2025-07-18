import logging
import requests
import gradio as gr
from typing import List, Tuple
import os

API_URL = os.getenv("API_URL", "http://chatbot-api:8000/chat")
UI_PORT = os.getenv("UI_PORT", 7860)
LANGUAGE = [
    "Spanish",
    "Euskara",
    "Catalan",
    "Italian",
    "French",
    "portuguese"
]

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
current_level = getattr(logging, log_level, logging.INFO)

logging.basicConfig(level=current_level)  # or INFO in production
logger = logging.getLogger(__name__)

class ChatbotApp:
    def __init__(self):
        self.setup_gradio()

    def setup_gradio(self) -> None:
        self.interface = gr.ChatInterface(
            fn=self.handle_chat,
            title="chatBotKube Language Learning Assistant",
            description=(
                "Welcome! Please tell me your language by clicking a button to begin. "
            ),
            theme=gr.themes.Soft(
                primary_hue="blue",
                secondary_hue="blue",
                neutral_hue="slate",
                radius_size="md",
                text_size="md",
            ),
            examples=LANGUAGE
        )
        logger.info("Gradio UI setup is complete")

    def handle_chat(self, message: str, history: List[Tuple[str, str]]) -> str:
        try:
            response = requests.post(API_URL, json={
                "message": message,
                "history": history
            })
            response.raise_for_status()
            return response.json()["reply"]
        except Exception as e:
            logger.exception(f"Error: {str(e)}")
            return f"Error: {str(e)}"

    def launch(self) -> None:
        self.interface.launch(
            share=False,
            server_name="0.0.0.0",
            server_port=UI_PORT,
            show_error=True,
            show_api=False,
        )
