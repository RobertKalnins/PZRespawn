#!/bin/bash

# Path to your .env file
ENV_PATH="./.env"

# Database connection details
echo "Enter the database name: "
read -r DB_NAME

echo "Enter the database user: "
read -r DB_USER

# Prompt for the database password, input is hidden
echo "Enter the database password: "
read -sr DB_PASSWORD
echo # Move to a new line

# Loop through each line in the .env file
while IFS= read -u 10 line; do
    if [[ $line =~ PLAYER_[0-9]+=\"(.+):([0-9]{4})\" ]]; then
        CHARACTER_NAME="${BASH_REMATCH[1]}"
        PASSCODE="${BASH_REMATCH[2]}"

        # Prompt for the nickname for this character
        echo "Enter nickname for $CHARACTER_NAME:"
        read -r NICKNAME

        # Use psql to check if the nickname already exists
        EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t \
			-c "SELECT EXISTS(SELECT 1 FROM players WHERE nickname='$NICKNAME');")

        if [[ $EXISTS =~ t ]]; then
            # Insert the character into the players second character
            echo "Nickname already exists, Inserting ingame name into $NICKNAME 's second ingame name..."
            # Update players table
            PGPASSWORD=$DB_PASSWORD psql -h localhost -U "$DB_USER" -d "$DB_NAME" \
				-c "UPDATE players SET ingame_name_2 = '$CHARACTER_NAME' WHERE nickname = '$NICKNAME';"
        else
            echo "Inserting new player with nickname $NICKNAME..."
            # Insert character into players table
            PGPASSWORD=$DB_PASSWORD psql -h localhost -U "$DB_USER" -d "$DB_NAME" \
				-c "INSERT INTO players (ingame_name_1, nickname) VALUES ('$CHARACTER_NAME', '$NICKNAME');"
			# Get player ID matching nickname
			PLAYER_ID=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t \
				-c "SELECT player_id FROM players WHERE nickname='$NICKNAME';")
			# Insert passcode into player_auth table
            PGPASSWORD=$DB_PASSWORD psql -h localhost -U "$DB_USER" -d "$DB_NAME" \
				-c "INSERT INTO player_auth (player_id, password) VALUES ('$PLAYER_ID', '$PASSCODE');"
        fi
    fi
done 10< "$ENV_PATH"
