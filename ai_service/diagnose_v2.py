import google.generativeai as genai
import sys

API_KEY = "AIzaSyB1YL5hTHr2I3Fpys1Jr4rDW2CkP8nwdbQ"
genai.configure(api_key=API_KEY)

with open("ai_service/diag_results.txt", "w") as f:
    f.write(f"Python: {sys.version}\n")
    try:
        f.write("Available Models:\n")
        for m in genai.list_models():
            f.write(f"- {m.name}\n")
    except Exception as e:
        f.write(f"Error: {e}\n")
print("Diagnostics saved to ai_service/diag_results.txt")
