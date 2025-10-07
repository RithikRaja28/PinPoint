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
app.register_blueprint(auth, url_prefix="/api/auth")
app.register_blueprint(alerts_bp, url_prefix="/api")
app.register_blueprint(responses_bp, url_prefix="/api")
app.register_blueprint(appeals_bp, url_prefix="/api")
app.register_blueprint(proxy_bp, url_prefix="/")  # ✅ mount proxy routes
app.register_blueprint(payload_bp, url_prefix="/api/payloads") 

if __name__ == "__main__":
    app.run(debug=True, port=5000)
