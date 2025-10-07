from flask import Flask
from flask_cors import CORS
from routes.poster import poster

app = Flask(__name__)
CORS(
    app,
    resources={r"/*": {"origins": "*"}},   # ✅ allow all origins
    supports_credentials=True,             # allow cookies/authorization headers
    allow_headers="*",                     # ✅ allow all custom headers
    expose_headers="*",                    # ✅ expose all headers to client
    methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]  # ✅ full set of methods
)
# Register blueprints
app.register_blueprint(poster, url_prefix="/api")

if __name__ == "__main__":
    app.run(debug=True, port=5000)
