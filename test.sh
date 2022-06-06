#!/usr/bin/env bash

# Admin API key goes here
KEY="628781fa5c13291a08b9d59e:93a1f60dff5df328fa6f9927952c6d71759519a945cbc4db335dc9e436af7a4c"

# Split the key into ID and SECRET
TMPIFS=$IFS
IFS=':' read ID SECRET <<< "$KEY"
IFS=$TMPIFS

# Prepare header and payload
NOW=$(date +'%s')
FIVE_MINS=$(($NOW + 300))
HEADER="{\"alg\": \"HS256\",\"typ\": \"JWT\", \"kid\": \"$ID\"}"
PAYLOAD="{\"iat\":$NOW,\"exp\":$FIVE_MINS,\"aud\": \"/v3/admin/\"}"

# Helper function for perfoming base64 URL encoding
base64_url_encode() {
    declare input=${1:-$(</dev/stdin)} 
    # Use `tr` to URL encode the output from base64.
    printf '%s' "${input}" | base64 | tr -d '=' | tr '+' '-' | tr '/' '_'
}

# Prepare the token body
header_base64=$(base64_url_encode "$HEADER")
payload_base64=$(base64_url_encode "$PAYLOAD")

header_payload="${header_base64}.${payload_base64}"

# Create the signature
signature=$(printf '%s' "${header_payload}" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$SECRET | base64_url_encode)

# Concat payload and signature into a valid JWT token

TOKEN="${header_payload}.${signature}"

# Make an authenticated request to create a post
curl -H "Authorization: Ghost $TOKEN" \
-H "Content-Type: application/json" \
-H "Accept-Version: v3.0" \
-d '{"posts":[{"title":"Hello world"}]}' \
"http://ghost-alb-1906027259.us-east-2.elb.amazonaws.com/ghost/api/v3/admin/posts/"
