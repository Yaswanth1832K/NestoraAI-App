import sys
import os

# Add the ai_service directory to path so we can import our main app
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'ai_service'))

from main import app as application

# This variable 'app' is what Vercel looks for
app = application
