import os
from pathlib import Path
from dotenv import load_dotenv
from google import genai

def main() -> None:
    # Load environment variables from ~/.env
    env_path = Path.home() / '.env'
    load_dotenv(env_path)

    # Check if API key exists
    api_key = os.getenv('GOOGLE_API_KEY')

    if not api_key:
        raise RuntimeError(
            " Error: GOOGLE_API_KEY not found in ~/.env"
        )

    client = genai.Client(api_key=api_key) 
    response = client.models.generate_content(
        model="gemini-flash-latest",
        contents="reply with exactly two words: 'environment is ready'",
    )
        
    print("\nModel Reply:")
    print(response.text)

    usage = getattr(response, 'usage_metadata', None)
    if usage:
        prompt_tokens = getattr(usage, 'prompt_token_count', 'N/A')
        response_tokens = getattr(usage, 'candidates_token_count', 'N/A')
        print(f"Prompt tokens:  {prompt_tokens}")   
        print(f"Response tokens: {response_tokens}")
        
if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f" Error: {e}")
        exit(1)