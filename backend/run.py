from app import create_app
from app.db import db

app = create_app()


@app.route("/ping_db")
def ping_db():
    try:
        result = db.session.execute("SELECT 1").scalar()
        return {"status": "connected", "result": result}
    except Exception as e:
        return {"status": "error", "details": str(e)}
    
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8000)
