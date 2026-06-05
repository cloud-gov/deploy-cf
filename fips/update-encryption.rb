existing_encrypted_value = ENV['EXISTING_ENCRYPTED_VALUE']
existing_salt = ENV['EXISTING_SALT']
current_key_name = ENV['CURRENT_KEY_NAME']

new_salt = VCAP::CloudController::Encryptor.generate_salt
if existing_encrypted_value == "" || existing_encrypted_value == "null"
    content="{\"existing_encrypted_value\": \"\", \"existing_salt\": \"#{existing_salt}\", \"new_encrypted_value\": \"\", \"new_salt\": \"#{new_salt}\"}"
else 
    decrypted_value = VCAP::CloudController::Encryptor.decrypt(existing_encrypted_value, existing_salt, iterations: 2048, label: current_key_name)
    new_encrypted_value = VCAP::CloudController::Encryptor.encrypt(decrypted_value, new_salt)

    decrypted_new_value = VCAP::CloudController::Encryptor.decrypt(new_encrypted_value, new_salt, iterations: 2048, label: current_key_name)

    if decrypted_new_value != decrypted_value 
        content="{\"error\": \"Encypted values do not match\" \"existing_encrypted_value\": \"#{existing_encrypted_value}\", \"existing_salt\": \"#{existing_salt}\", \"new_encrypted_value\": \"#{new_encrypted_value}\", \"new_salt\": \"#{new_salt}\"}"
    else     
        content="{\"existing_encrypted_value\": \"#{existing_encrypted_value}\", \"existing_salt\": \"#{existing_salt}\", \"new_encrypted_value\": \"#{new_encrypted_value}\", \"new_salt\": \"#{new_salt}\"}"
    end
end

File.open('/var/vcap/tmp/deploy-cf/fips/ruby_output.json', 'w') do |fo|
  fo.write(content)
end

