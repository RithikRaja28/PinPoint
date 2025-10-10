import os
import re
from google import genai
from dotenv import load_dotenv

load_dotenv()

from shop_model import ShopModel

# ✅ Load API Key from .env
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise ValueError("❌ GEMINI_API_KEY missing in .env file")

# Initialize Gemini Client
client = genai.Client(api_key=API_KEY)

def extract_amount_and_category(prompt: str):
    """
    Use Gemini API to extract amount and category from user's prompt.
    Example: "I have 300 rupees for clothes"
    → {'amount': 300, 'category': 'clothes'}
    """
    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=f"""
            You are a smart text parser. Extract the spending amount and category from this sentence:
            '{prompt}'.
            Return strictly in JSON format like this:
            {{ "amount": 300, "category": "food" }}
            If no clear category is found, return null for category.
            """
        )

        import json
        text = response.text.strip()
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            data = json.loads(match.group())
            return data
        else:
            return None
    except Exception as e:
        print("⚠️ Error extracting data:", e)
        return None


def generate_sql_query(prompt: str):
    """
    Takes user prompt → Extracts amount & category → Returns SQL query.
    """
    data = extract_amount_and_category(prompt)
    if not data or "amount" not in data or not data["amount"]:
        return "⚠️ Unable to extract valid amount/category."

    amount = float(data["amount"])
    category = data.get("category", "").strip().lower()

    lower_bound = amount - 50
    upper_bound = amount + 50

    # ✅ Build SQL Query for shops within similar avg_spend range and category
    if category:
        sql_query = f"""
        SELECT *
        FROM shops
        WHERE category ILIKE '%{category}%'
        AND avg_spend BETWEEN {lower_bound} AND {upper_bound}
        ORDER BY ABS(avg_spend - {amount}) ASC
        LIMIT 10;
        """
    else:
        sql_query = f"""
        SELECT *
        FROM shops
        WHERE avg_spend BETWEEN {lower_bound} AND {upper_bound}
        ORDER BY ABS(avg_spend - {amount}) ASC
        LIMIT 10;
        """

    return sql_query


# 🔹 Example Usage
if __name__ == "__main__":
    user_prompt = "I have 300 rupees to spend on street food"
    print("🔹 User Prompt:", user_prompt)
    print("🔍 Generated SQL Query:\n")
    print(generate_sql_query(user_prompt))
