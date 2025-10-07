from app import create_app


app = create_app()
"""
🧱 Step 3: Activate your virtual environment

Since your venv is already created, just run:

.\venv\Scripts\Activate.ps1


If you see your prompt change to:

(venv) PS D:\PROJECTS\deployed\PinPoint\backend>🧱 Step 3: Activate your virtual environment

Since your venv is already created, just run:

.\venv\Scripts\Activate.ps1


If you see your prompt change to:

(venv) PS D:\PROJECTS\deployed\PinPoint\backend>
"""
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)