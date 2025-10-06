enable_anonymous_sign_ins = true
signing_keys_path = "./signing_keys.json"

both uncommented in config.toml

supabase gen signing-key
supabase start

docker compose --file ./docker/compose.yaml --en
v-file .env.local up -d


flutter run -d emulator-5554 --no-dds --disable-service-auth-codes --no-pub