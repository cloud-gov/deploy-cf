existing_encrypted_value = ENV['EXISTING_ENCRYPTED_VALUE']
existing_salt = ENV['EXISTING_SALT']
current_key_name = ENV['CURRENT_KEY_NAME']

decrypted_value = Encryptor.decrypt(existing_encrypted_value, existing_salt, iterations: 2048, label: current_key_name)
new_salt = VCAP::CloudController::Encryptor.generate_salt
new_encrypted_value = Encryptor.encrypt(decrypted_value, new_salt)

decrypted_new_value = Encryptor.decrypt(new_encrypted_value, new_salt, iterations: 2048, label: current_key_name)

if decrypted_new_value = decrypted_value 
    puts "UPDATE_ENCRYPTION_RESULT: {\"error\": \"Encypted values do not match\"}"
else     
    puts "UPDATE_ENCRYPTION_RESULT: {\"existing_encrypted_value\": \"#{existing_encrypted_value}\", \"existing_salt\": \"#{existing_salt}\", \"new_encrypted_value\": \"#{new_encrypted_value}\", \"new_salt\": \"#{new_salt}\"}"
end