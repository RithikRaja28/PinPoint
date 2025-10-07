import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    """Configuration class for Flask app."""

    # Flask settings
    SECRET_KEY = os.getenv("SECRET_KEY", "default_secret_key")
    FLASK_ENV = os.getenv("FLASK_ENV", "development")

    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT secret (if needed)
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "default_jwt_secret")

    # Nokia API config
    NOKIA_BASE_URL = os.getenv("NOKIA_BASE_URL", "https://network-as-code.p-eu.rapidapi.com")
    NOKIA_RAPIDAPI_KEY = os.getenv("NOKIA_RAPIDAPI_KEY")
    NOKIA_RAPIDAPI_HOST = os.getenv("NOKIA_RAPIDAPI_HOST", "network-as-code.nokia.rapidapi.com")
