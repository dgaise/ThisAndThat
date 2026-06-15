import random
from typing import Tuple

import gymnasium as gym
import numpy as np

ALPHA = 0.8
GAMMA = 0.95
EPSILON = 1.0
EPSILON_DECAY = 0.995
EPSILON_MIN = 0.05
EPISODES = 2000
MAX_STEPS = 100

def choose_action(q_table: np.ndarray, state: int, epsilon: float) -> int:
    if random.random() < epsilon:
        return random.randint(0, q_table.shape[1] - 1)
    return int(np.argmax(q_table[state]))

def train_agent() -> Tuple[np.ndarray, list[float]]:
    env = gym.make('FrozenLake-v1', is_slippery=False)
    q_table = np.zeros((env.observation_space.n, env.action_space.n))
    epsilon = EPSILON
    rewards = []

    for _ in range(EPISODES):
        state, _ = env.reset()
        
        for _ in range(MAX_STEPS):
            action = choose_action(q_table, state, epsilon)
            next_state, reward, terminated, truncated, _ = env.step(action)

            best_next_value = np.max(q_table[next_state])
            old_value = q_table[state, action]
            q_table[state, action] = old_value + ALPHA * (
                reward + GAMMA * best_next_value - old_value
            )

            state = next_state
            if terminated or truncated:
                break

        epsilon = max(EPSILON_MIN, epsilon * EPSILON_DECAY)

    return q_table, rewards

def evaluate_agent(q_table: np.ndarray, env: gym.Env) -> None:
    action_names = {
        0: 'Left',
        1: 'Down',
        2: 'Right',
        3: 'Up'
    }

    state, _ = env.reset()
    print(f"Starting state: {state}")

    for step_number in range(1, MAX_STEPS + 1):
        action = int(np.argmax(q_table[state]))
        action_name = action_names[action]
        print(f"Step {step_number}: Action: {action_name} (Q-value: {q_table[state, action]:.2f})")

        next_state, reward, terminated, truncated, _ = env.step(action)
        print(f"Next state: {next_state}, Reward: {reward}")

        state = next_state

        if terminated:
            print("Episode finished successfully!")
            break
        elif truncated:
            print("Episode ended due to max steps.")
            break

if __name__ == "__main__":
    print("Training agent...")
    q_table, rewards = train_agent()
    
    print("\n" + "="*50)
    print("Learned Q-Table:")
    print("="*50)
    print("\nRows = States (0-15), Columns = Actions (Left, Down, Right, Up)")
    print(q_table)
    print("\nQ-Table shape:", q_table.shape)
    
    print("\n" + "="*50)
    print("Evaluating trained agent...")
    print("="*50)
    env = gym.make('FrozenLake-v1', is_slippery=False)
    evaluate_agent(q_table, env)