#!/bin/bash

API_TOKEN="8181721967:AAGXvpHE0EZteI6ethqq-hMhExnspB1bYpY"
BASE_URL="https://api.telegram.org/bot$API_TOKEN"
INSTAGRAM_API="https://i.instagram.com/api/v1/users/lookup/"
TRUECALLER_API="https://api.truecaller.com/v1/lookup"

send_telegram_message() {
    local chat_id=$1
    local text=$2
    curl -s -X POST "$BASE_URL/sendMessage" -d chat_id="$chat_id" -d text="$text"
}

send_keyboard() {
    local chat_id=$1
    curl -s -X POST "$BASE_URL/sendMessage" \
        -d chat_id="$chat_id" \
        -d text="Choose an option:" \
        -d reply_markup='{"keyboard":[["Admin ☠","IG OSINT ☠"],["Actress Admirers❤","PhoneInfo📞"]],"resize_keyboard":true}'
}

get_instagram_info() {
    local username=$1
    local response=$(curl -s -X POST "$INSTAGRAM_API" \
        -H "User-Agent: Instagram 101.0.0.15.120" \
        -d "q=$username")
    
    # Check if the response contains user data
    user_status=$(echo "$response" | jq -r '.user.status')
    
    if [[ "$user_status" == "fail" ]]; then
        send_telegram_message "$chat_id" "No username found or it's a verified account."
    else
        # Extract relevant user data
        local full_name=$(echo "$response" | jq -r '.user.full_name')
        local username=$(echo "$response" | jq -r '.user.username')
        local followers=$(echo "$response" | jq -r '.user.followers_count')
        local following=$(echo "$response" | jq -r '.user.following_count')
        
        send_telegram_message "$chat_id" "Instagram Info for $username:\nFull Name: $full_name\nFollowers: $followers\nFollowing: $following"
    fi
}

get_phone_info() {
    local phone_number=$1
    local country_code=$2
    local response=$(curl -s -X GET "$TRUECALLER_API/lookup" \
        -d "number=$phone_number" -d "countryCode=$country_code" -d "apiKey=a1i0q--gY7qq2-c-IbuuAC96o2kttqyeNvZC9MTB-tx-5fyOQk5wu1-cs6sL4s4N")
    
    local name=$(echo "$response" | jq -r '.data[0].name')
    local gender=$(echo "$response" | jq -r '.data[0].gender')
    local carrier=$(echo "$response" | jq -r '.data[0].phones[0].carrier')
    local city=$(echo "$response" | jq -r '.data[0].addresses[0].city')
    
    send_telegram_message "$chat_id" "Phone Info for $phone_number:\nName: $name\nGender: $gender\nCarrier: $carrier\nCity: $city"
}

# Handle incoming messages
handle_message() {
    local message=$1
    local chat_id=$2
    if [[ "$message" == "/start" ]]; then
        send_keyboard "$chat_id"
    elif [[ "$message" == "Admin ☠" ]]; then
        send_telegram_message "$chat_id" "Admin --> @placements_VR"
    elif [[ "$message" == "Actress Admirers❤" ]]; then
        send_telegram_message "$chat_id" "--> @Actress_Admirerss"
    elif [[ "$message" == "IG OSINT ☠" ]]; then
        send_telegram_message "$chat_id" "Send me Instagram Username: "
    elif [[ "$message" == "PhoneInfo📞" ]]; then
        send_telegram_message "$chat_id" "Send me a Mobile Number with Country Code: Example +91830xxxxxxx"
    elif [[ "$message" =~ ^\+?[0-9]+$ ]]; then
        # If the message is a phone number
        get_phone_info "$message" "IN"
    else
        get_instagram_info "$message"
    fi
}

# Long polling for new messages
long_polling() {
    offset=0
    while true; do
        response=$(curl -s "$BASE_URL/getUpdates?offset=$offset")
        messages=$(echo "$response" | jq -r '.result[]')
        
        for message in $(echo "$messages" | jq -r '.message.text'); do
            chat_id=$(echo "$message" | jq -r '.chat.id')
            handle_message "$message" "$chat_id"
            offset=$(echo "$response" | jq -r '.result[-1].update_id + 1')
        done
        sleep 1
    done
}

# Start the bot
long_polling
