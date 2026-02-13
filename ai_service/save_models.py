import google.generativeai as genai

API_KEY = "AIzaSyCRr8Y8Iy-EDGjiSmbFs_d9N85Dw4KP3qA"

genai.configure(api_key=API_KEY)

with open("models_list.txt", "w", encoding="utf-8") as f:
    f.write("Available Gemini Models:\n")
    f.write("=" * 60 + "\n\n")
    
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            f.write(f"{m.name}\n")

print("Models saved to models_list.txt")
