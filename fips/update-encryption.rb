# EXISTING_ENCRYPTED_VALUE
# EXISTING_SALT
# CURRENT_KEY_NAME

decrypted_value = Encryptor.decrypt("#{EXISTING_ENCRYPTED_VALUE}", "#{EXISTING_SALT}", iterations: 2048, label: "#{CURRENT_KEY_NAME}")
new_salt = VCAP::CloudController::Encryptor.generate_salt
new_encrypted_value = Encryptor.encrypt(decrypted_value, new_salt)

decrypted_new_value = Encryptor.decrypt("#{new_encrypted_value}", "#{new_salt}", iterations: 2048, label: "#{CURRENT_KEY_NAME}")

if decrypted_new_value != decrypted_value 
    puts "{\"error\": \"Encypted values don't match\"}"
else     
    puts "{\"existing_encrypted_value\": \"#{EXISTING_ENCRYPTED_VALUE}\", \"existing_salt\": \"#{EXISTING_SALT}\", \"new_encrypted_value\": \"#{new_encrypted_value}\", \"new_salt\": \"#{new_salt}\"}"
end