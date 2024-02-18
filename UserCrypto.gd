extends RefCounted
class_name UserCrypto

func generate_salt(length = 32):
	var crypto = Crypto.new()
	return crypto.generate_random_bytes(length).hex_encode()

func hash_password(password, salt):
	var password_data = password.to_utf8_buffer()
	var salt_data = salt.to_utf8_buffer()
	var combined_data = password_data + salt_data

	var hashing_context = HashingContext.new()
	hashing_context.start(HashingContext.HASH_SHA256)
	hashing_context.update(combined_data)
	var hash = hashing_context.finish()

	return hash.hex_encode()	

func CreateCert():
	var crypto = Crypto.new()
	var key = CryptoKey.new()
	var cert = X509Certificate.new()
	# Generate new RSA key.
	key = crypto.generate_rsa(4096)
	# Generate new self-signed certificate with the given key.
	cert = crypto.generate_self_signed_certificate(key, "CN=mydomain.com,O=My Game Company,C=IT")
	# Save key and certificate in the user folder.
	key.save("res://my_server_key.key")
	cert.save("res://my_server_cas.crt")

	
