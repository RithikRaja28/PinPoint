import os
import re
import json
import pandas as pd
from google import genai  # ✅ Google Gemini SDK
from dotenv import load_dotenv

# ----------------------------------------------------------
# 🔹 Load environment variables
# ----------------------------------------------------------
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    raise ValueError("❌ GEMINI_API_KEY missing in .env file. Please add it.")

# ----------------------------------------------------------
# 🔹 Initialize Gemini client
# ----------------------------------------------------------
client = genai.Client(api_key=API_KEY)

# ----------------------------------------------------------
# 🔹 CSV path setup
# ----------------------------------------------------------
CSV_PATH = os.path.join(os.path.dirname(__file__), "../data/shops.csv")

if not os.path.exists(CSV_PATH):
    raise FileNotFoundError(f"❌ CSV file not found at: {CSV_PATH}")

# Load the CSV data
df = pd.read_csv(CSV_PATH)

# Normalize column names
df.columns = [c.strip().lower() for c in df.columns]


# ----------------------------------------------------------
# 🧠 Gemini extraction function
# ----------------------------------------------------------
def extract_amount_and_category(prompt: str):
    """
    Use Gemini to extract the user's budget and category from their text.
    Example prompt: "I have 300 rs to spend on street food"
    Expected output: { "amount": 300, "category": "street food" }
    """
    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=f"""
            Extract the amount and category from this sentence:
            '{prompt}'
            Return strictly in JSON format as:
            {{ "amount": 300, "category": "street food" }}
            If amount or category is missing, use null.
            """
        )

        text = response.text.strip()
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            data = json.loads(match.group())
            return data
        else:
            return None
    except Exception as e:
        print("⚠️ Gemini extraction error:", e)
        return None


# ----------------------------------------------------------
# 🔍 Recommend shops from CSV
# ----------------------------------------------------------
def recommend_from_csv(prompt: str):
    """
    Extract amount/category using Gemini,
    filter CSV shops where avg_spend ≈ amount ± 50
    and category matches partially.
    """
    extracted = extract_amount_and_category(prompt)
    if not extracted:
        return {"error": "Could not extract valid data from prompt."}

    amount = float(extracted.get("amount", 0) or 0)
    category = (extracted.get("category") or "").strip().lower()

    if amount == 0 and not category:
        return {"error": "No valid amount or category found."}

    # Amount range (±50)
    lower = amount - 50
    upper = amount + 50

    filtered = df.copy()

    if "avg_spend" in df.columns:
        filtered = filtered[
            (filtered["avg_spend"] >= lower) & (filtered["avg_spend"] <= upper)
        ]

    if category and "category" in df.columns:
        filtered = filtered[
            filtered["category"].astype(str).str.lower().str.contains(category, na=False)
        ]

    # Sort by closeness to entered amount
    if "avg_spend" in filtered.columns:
        filtered["diff"] = abs(filtered["avg_spend"] - amount)
        filtered = filtered.sort_values(by="diff")

    # Pick display columns
    display_cols = ["id", "name", "category", "avg_spend", "city", "description"]
    display_cols = [c for c in display_cols if c in filtered.columns]

    if filtered.empty:
        return {"message": "No matching shops found for this query."}

    # Limit top 10 results
    results = filtered[display_cols].head(10)

    return results.to_dict(orient="records")


# ----------------------------------------------------------
# 🧩 Test Run
# ----------------------------------------------------------
if __name__ == "__main__":
    print("🟣 PinPoint Recommendation Engine\n")
    user_prompt = input("Enter your spending query: ").strip()
    recommendations = recommend_from_csv(user_prompt)
    print("\n🔹 Recommendations:\n")
    print(json.dumps(recommendations, indent=2, ensure_ascii=False))
