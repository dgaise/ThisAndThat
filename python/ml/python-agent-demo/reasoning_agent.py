import os
import json
import requests

def main() -> None:

    user_goal = "A client wants a meeting tomorrow because a payment issue is blocking delivery. HGelp me reply properly."
    current_state = "We have a short list of internal notes and we need the next best step."

    print("User Goal:")
    print(user_goal)
    print("\nChoosing the next action...\n")

    decision = choose_action(llm, user_goal, current_state)
    print(f"Chosen Action: {decision['action']}")
    print(f"Reason: {decision['reason']}\n")

    tool_result = TOOLS[decision['action']](user_goal)
    memory.append(f"Action used: {decision['action']}")
    memory.append(f"Tool result: {tool_result}")

    print("Tool output:")
    print(tool_result)
    print("\nCurrent memory:")
    for item in memory:
        print(f" - {item}")

if __name__ == "__main__":
    main()  
