#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
curl -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# File name for the Python script
PYTHON_SCRIPT_NAME="request_script.py"
VENV_DIR="venv"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root (sudo)."
    exit 1
fi

# Check if Python is installed, and install it if not
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found, installing..."
    apt update
    apt install python3 -y
else
    echo "Python3 is already installed"
fi

# Install python3-venv if not installed
if ! dpkg -s python3-venv &> /dev/null; then
    echo "Installing python3-venv..."
    apt install python3-venv -y
else
    echo "python3-venv is already installed"
fi

# Check if pip is installed, and install it if not
if ! command -v pip3 &> /dev/null; then
    echo "pip3 not found, installing..."
    apt update
    apt install python3-pip -y
else
    echo "pip3 is already installed"
fi

# Install virtualenv if not installed
if ! pip3 show virtualenv &> /dev/null; then
    echo "Installing virtualenv..."
    pip3 install virtualenv
else
    echo "virtualenv is already installed"
fi

# Create a virtual environment
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Install the requests library if not installed
if ! pip3 show requests &> /dev/null; then
    echo "requests library not found, installing..."
    pip3 install requests
else
    echo "requests library is already installed"
fi

# Create the Python script
echo "Creating Python script..."
cat << EOF > $PYTHON_SCRIPT_NAME
import requests
import time
import random
import logging

# Logging configuration for console output
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")

# URL and headers for the request
url = input("Enter URL for the request: ")
headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json'
}

# 100 questions for randomization
questions = [
    "Where is Paris?", "What is the capital of Germany?", "How far is the moon from the Earth?",
    "Who wrote 'To Kill a Mockingbird'?", "What is the speed of light?", "How many continents are there?",
    "What is the tallest mountain in the world?", "Who painted the Mona Lisa?", "What is the largest ocean on Earth?",
    "How many planets are in our solar system?", "What is the capital of Japan?", "Who discovered penicillin?",
    "What is the longest river in the world?", "Who is the current president of the United States?",
    "What is the largest desert in the world?", "How many states are there in the USA?", "What is the smallest country in the world?",
    "Who was the first person to walk on the moon?", "What is the chemical symbol for gold?", "What is the highest waterfall in the world?",
    "What is the capital of Australia?", "Who wrote '1984'?", "What is the largest mammal?", "Who developed the theory of relativity?",
    "What is the fastest land animal?", "How many bones are in the human body?", "What is the largest island in the world?",
    "What is the most spoken language in the world?", "What is the capital of Canada?", "Who invented the telephone?",
    "What is the currency of Japan?", "What is the capital of Russia?", "What is the longest wall in the world?",
    "What is the most populous country in the world?", "What is the capital of Italy?", "What is the largest planet in the solar system?",
    "Who wrote 'Pride and Prejudice'?", "What is the largest lake in the world?", "What is the capital of India?",
    "Who painted the Sistine Chapel ceiling?", "What is the smallest bone in the human body?", "What is the capital of Brazil?",
    "What is the highest mountain in North America?", "What is the capital of China?", "Who wrote 'The Catcher in the Rye'?",
    "What is the deepest ocean trench?", "What is the capital of Mexico?", "Who discovered America?",
    "What is the chemical symbol for water?", "What is the largest coral reef system?", "Who is known as the father of computers?",
    "What is the capital of Argentina?", "What is the largest landlocked country?", "Who invented the light bulb?",
    "What is the longest river in Africa?", "What is the capital of South Africa?", "Who wrote 'Moby-Dick'?",
    "What is the speed of sound?", "What is the largest city in the world?", "What is the capital of Egypt?",
    "Who painted 'Starry Night'?", "What is the coldest place on Earth?", "What is the capital of Saudi Arabia?",
    "Who is the author of 'Harry Potter'?", "What is the highest building in the world?", "What is the capital of Spain?",
    "Who discovered the electron?", "What is the hottest planet in the solar system?", "What is the capital of Thailand?",
    "Who wrote 'The Great Gatsby'?", "What is the oldest known civilization?", "What is the capital of Turkey?",
    "Who invented the airplane?", "What is the largest rainforest in the world?", "What is the capital of Indonesia?",
    "Who painted 'The Last Supper'?", "What is the capital of Greece?", "Who developed the polio vaccine?",
    "What is the capital of Vietnam?", "What is the most abundant gas in the Earth's atmosphere?", "What is the capital of Iran?",
    "Who wrote 'The Odyssey'?", "What is the capital of Portugal?", "Who invented the printing press?",
    "What is the largest country in the world by area?", "What is the capital of Norway?", "Who wrote 'War and Peace'?",
    "What is the smallest ocean?", "What is the capital of Sweden?", "Who discovered gravity?",
    "What is the most populous city in the world?", "What is the capital of Kenya?", "Who wrote 'Don Quixote'?",
    "What is the largest river by volume?", "What is the capital of Peru?", "Who invented the World Wide Web?",
    "What is the capital of Pakistan?", "What is the most widely used programming language?", "What is the capital of Chile?",
    "Who wrote 'Crime and Punishment'?", "What is the capital of Malaysia?", "Who painted 'The Persistence of Memory'?"
]

# Function to send a request
def send_request():
    try:
        # Choose a random question
        question = random.choice(questions)
        # Form the request body
        data = {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": question}
            ]
        }
        logging.info(f"Sending request with question: {question}")
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            logging.info(f"Response: {response.json()}")
        else:
            logging.error(f"Error receiving response, status code: {response.status_code}")
    except Exception as e:
        logging.error(f"Error occurred while sending request: {str(e)}")

# Main loop
def main():
    sleep_hours = 8  # Sleep hours
    sleep_seconds = sleep_hours * 3600  # Convert to seconds

    while True:
        # Determine a random number of requests before a long break
        num_requests = random.randint(6, 12)  # From 6 to 12 requests (about an hour on average)

        for _ in range(num_requests):
            send_request()
            # Random delay between requests from 1 to 5 minutes
            delay = random.randint(60, 300)
            logging.info(f"Waiting {delay // 60} minutes...")
            time.sleep(delay)

        # Long break from 30 minutes to 1 hour
        long_break = random.randint(1800, 3600)
        logging.info(f"Taking a break for {long_break // 60} minutes...")
        time.sleep(long_break)

        # Sleep every 24 hours
        logging.info(f"Sleeping for {sleep_hours} hours...")
        time.sleep(sleep_seconds)

if __name__ == "__main__":
    main()
EOF

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "screen not found, installing..."
    apt install screen -y
else
    echo "screen is already installed"
fi

# Run the Python script in the background using screen
screen -dmS python_script_session bash -c "source $VENV_DIR/bin/activate && python3 $PYTHON_SCRIPT_NAME | tee -a request_script.log"

echo "Script $PYTHON_SCRIPT_NAME is running in the background using screen."
echo "To connect to the screen session and view the logs, use the command: screen -r python_script_session"
