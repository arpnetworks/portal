# Original source for AESCrypt:
# http://rails.brentsowers.com/2007/12/aes-encryption-and-decryption-in-ruby.html

module AESCrypt
  # Decrypts a block of data (encrypted_data) given an encryption key
  # and an initialization vector (iv).  Keys, iv's, and the data
  # returned are all binary strings.  Cipher_type should be
  # "AES-256-CBC", "AES-256-ECB", or any of the cipher types
  # supported by OpenSSL.  Pass nil for the iv if the encryption type
  # doesn't use iv's (like ECB).
  #:return: => String
  #:arg: encrypted_data => String
  #:arg: key => String
  #:arg: iv => String
  #:arg: cipher_type => String
  def AESCrypt.decrypt(encrypted_data, key, iv, cipher_type)
    aes = OpenSSL::Cipher.new(cipher_type)
    aes.decrypt
    aes.key = key[0..31]
    aes.iv = iv[0..15] if iv != nil
    aes.update(encrypted_data) + aes.final
  end

  # Encrypts a block of data given an encryption key and an
  # initialization vector (iv).  Keys, iv's, and the data returned
  # are all binary strings.  Cipher_type should be "AES-256-CBC",
  # "AES-256-ECB", or any of the cipher types supported by OpenSSL.
  # Pass nil for the iv if the encryption type doesn't use iv's (like
  # ECB).
  #:return: => String
  #:arg: data => String
  #:arg: key => String
  #:arg: iv => String
  #:arg: cipher_type => String
  def AESCrypt.encrypt(data, key, iv, cipher_type)
    aes = OpenSSL::Cipher.new(cipher_type)
    aes.encrypt
    aes.key = key[0..31]
    aes.iv = iv[0..15] if iv != nil
    aes.update(data) + aes.final
  end
end

module SimpleCrypt
  KEY = $SIMPLE_CRYPT_KEY

  class <<self
    def encrypt(s, iv = nil)
      AESCrypt.encrypt(s, KEY, iv, 'AES-256-CBC')
    end

    def decrypt(s, iv = nil)
      AESCrypt.decrypt(s, KEY, iv, 'AES-256-CBC')
    end
  end
end
