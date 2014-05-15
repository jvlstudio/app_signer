# app_signer

app_signer is a tool to re-sign iOS .app files to create a new .ipa with a given
provisioning profile and certificate.

## Usage

### Explanation of Parameters

* `app_path` - Path to the iOS .app file to be signed.
* `provisioning_profile_path` - Path to the provisioning profile to be used to
sign the ipa.
* `signing_identity` - Common name in the certificate to be used to sign the
ipa. This can be found by opening the keychain, right clicking the certificate,
and clicking 'get info'.
* `signing_identity_SHA1` - SHA1 of the certificate to be used to sign the app.
This can be found by opening the keychain, right clicking the certificate,
and clicking 'get info'. This is needed because it's possible to have two
certificates with the same common name.
* `generated_ipa_name` - Name to use for the generated ipa file
* `bundle_id` - Used to changed the bundle id during re-signing. *(optional)*

### In a Ruby Script

```ruby
require 'app_signer'

# Create signer
signer = AppSigner::Signer.new

# Set needed params
signer.app_path = # path to .app
signer.provisioning_profile_path = # path to provisioning profile
signer.signing_identity = # signing identity common name
signer.signing_identity_SHA1 = # signing identity SHA1
signer.generated_ipa_name = # name for generated ipa
signer.bundle_id = # optional new bundle id to use in info plist

# Create new ipa
signer.sign
```

### From the Command Line

```bash
app_signer --app-path PATH_TO_APP\
 --profile-path PATH_TO_PROVISIONING_PROFILE\
 --signing-identity SIGNING_IDENTITY\
 --signing-identity-SHA1 SIGNING_IDENTITY_SHA1\
 --ipa-name IPA_NAME\
 --bundle-id OPTIONAL_NEW_BUNDLE_ID
 ```
