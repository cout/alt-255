// An RSA module for Ruby; uses openssl for its dirty-work

#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <ruby.h>

// When an SSL error occurs, use this macro to throw the error as a Ruby
// exception.
#define RB_RAISE_OPENSSL_ERROR \
    rb_raise(rb_eRuntimeError, ERR_error_string(ERR_get_error(), NULL))

// Two key types: public and private.
#define RSA_PRIVATE_KEY 0
#define RSA_PUBLIC_KEY 1

// Standard padding.
#define PADDING_MODE RSA_PKCS1_PADDING

// Read an RSA key from a string.  The string should be in a format that the
// PEM functions can read.  Specify key_type == RSA_PRIVATE_KEY for private
// keys, and key_type == RSA_PUBLIC_KEY for public keys.  Returns a pointer
// to an RSA structure that should be freed with RSA_free when the user is
// done with it.
static RSA * read_key(const char * key, size_t key_len, int key_type) {
    RSA * rsa;
    BIO * bio;

    bio = BIO_new(BIO_s_mem());
    BIO_write(bio, key, key_len);

    switch(key_type) {
        case RSA_PRIVATE_KEY:
            rsa = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, NULL);
            break;
        case RSA_PUBLIC_KEY:
            rsa = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
            break;
        default:
            return 0;
    }

    BIO_free(bio);
    return rsa;
}

// A Ruby function for encrypting a string using a public or private key.
VALUE ruby_RSA_encrypt(
        VALUE self,
        VALUE rb_key, VALUE rb_key_type, VALUE rb_msg) {

    char * msg = STR2CSTR(rb_msg);
    char * key = STR2CSTR(rb_key);
    size_t msg_len = RSTRING(rb_msg)->len;
    size_t key_len = RSTRING(rb_key)->len;
    int key_type = NUM2INT(rb_key_type);

    RSA * rsa;

    char * out;
    int out_len;

    // Read the key
    if ((rsa = read_key(key, key_len, key_type)) == NULL) {
        RB_RAISE_OPENSSL_ERROR;
    }

    // Encrypt the message
    out = ALLOCA_N(char, RSA_size(rsa));
    switch(key_type) {
        case RSA_PRIVATE_KEY:
            out_len = RSA_private_encrypt(msg_len, msg, out, rsa, PADDING_MODE);
            break;
        case RSA_PUBLIC_KEY:
            out_len = RSA_public_encrypt(msg_len, msg, out, rsa, PADDING_MODE);
            break;
        default:
            return Qnil;
    }

    // Check for error
    if(out_len < 0) {
        RB_RAISE_OPENSSL_ERROR;
    }

    // Free the RSA structure
    RSA_free(rsa);

    // Return the encrypted string
    return rb_str_new(out, out_len);
}

// A Ruby function for decrypting a string using a public or private key.
VALUE ruby_RSA_decrypt(
        VALUE self,
        VALUE rb_key, VALUE rb_key_type, VALUE rb_msg) {

    char * msg = STR2CSTR(rb_msg);
    char * key = STR2CSTR(rb_key);
    size_t msg_len = RSTRING(rb_msg)->len;
    size_t key_len = RSTRING(rb_key)->len;
    int key_type = NUM2INT(rb_key_type);

    RSA * rsa;

    char * out;
    int out_len;

    // Read the key
    if ((rsa = read_key(key, key_len, key_type)) == NULL) {
        RB_RAISE_OPENSSL_ERROR;
    }

    // Decrypt the message
    out = ALLOCA_N(char, RSA_size(rsa));

    switch(key_type) {
        case RSA_PRIVATE_KEY:
            out_len = RSA_private_decrypt(msg_len, msg, out, rsa, PADDING_MODE);
            break;
        case RSA_PUBLIC_KEY:
            out_len = RSA_public_decrypt(msg_len, msg, out, rsa, PADDING_MODE);
            break;
        default:
            return Qnil;
    }

    // Check for error
    if(out_len < 0) {
        RB_RAISE_OPENSSL_ERROR;
    }
        
    // Free the RSA structure
    RSA_free(rsa);

    // Return the decrypted string
    return rb_str_new(out, out_len);
}

// Initialize the Ruby RSA module.
void Init_rsa_ext() {
    VALUE cRSA = rb_define_class("RSA", rb_cObject);

    rb_define_singleton_method(cRSA, "encrypt", ruby_RSA_encrypt, 3);
    rb_define_singleton_method(cRSA, "decrypt", ruby_RSA_decrypt, 3);

    rb_define_const(cRSA, "PUBLIC_KEY", INT2NUM(RSA_PUBLIC_KEY));
    rb_define_const(cRSA, "PRIVATE_KEY", INT2NUM(RSA_PRIVATE_KEY));

    // OpenSSL_add_all_algorithms();
    // OpenSSL_add_all_ciphers();
    // OpenSSL_add_all_digests();
    ERR_load_crypto_strings();
}
