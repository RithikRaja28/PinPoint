from flask import Blueprint, request, jsonify
from models.recommendation_query import recommend_from_csv

recommend_bp = Blueprint("recommend", __name__)

@recommend_bp.route("/recommend", methods=["POST"])
def get_recommendations():
    print("🔍 Recommendation route registered at /api/recommend");
    """
    Expects JSON: { "prompt": "I have 250 rs for coffee" }
    Returns: list of matching shop suggestions.
    """
    try:
        data = request.get_json()
        if not data or "prompt" not in data:
            return jsonify({"error": "Missing 'prompt' in request"}), 400

        prompt = data["prompt"]
        recommendations = recommend_from_csv(prompt)
        return jsonify({"results": recommendations}), 200
    except Exception as e:
        print("❌ Error in /recommend:", e)
        return jsonify({"error": str(e)}), 500
