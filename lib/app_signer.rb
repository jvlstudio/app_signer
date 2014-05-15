require 'plist'
require 'openssl'

# AppSigner is an easy way to resign iOS apps. This module contains only one
# class {AppSigner::Signer} which contains all functionality.
module AppSigner

  # Used to resign iOS .app files. Generates a .ipa based upon the set
  # attributes when calling {AppSigner::Signer#sign}
  class Signer

    # @!attribute app_path
    #   @return [String] path to the .app file to be resigned
    attr_accessor :app_path

    # @!attribute provisioning_profile_path
    #   @return [String] path to provisioning profile to be used during signing
    attr_accessor :provisioning_profile_path

    # @!attribute signing_identity
    #   @return [String] signing identity of the certificate to be used to sign
    attr_accessor :signing_identity

    # @!attribute bundle_id
    #   @return [String] bundle id to set in the resigned ipa's info plist
    attr_accessor :bundle_id

    # @!attribute signing_identity_SHA1
    #   @return [String] SHA1 of certificate to be used during signing
    attr_reader :signing_identity_SHA1

    # @!attribute signing_identity_SHA1
    #   @return [String] name tp be used for the generated .ipa
    attr_accessor :generated_ipa_name

    # Sets signing_identity_SHA1 by removing spaces in the giving hash
    def signing_identity_SHA1=(value)
      @signing_identity_SHA1 = value.gsub(" ", "")
    end

    # Extracts XML from provisioning profile to be used to for obtaining proper
    # entitlements
    #
    # @param signed_data [String] contents of provisioing profile
    # @return [String]
    def unwrap_signed_data(signed_data)
      pkcs7 = OpenSSL::PKCS7.new(signed_data)
      store = OpenSSL::X509::Store.new
      flags = OpenSSL::PKCS7::NOVERIFY
      pkcs7.verify([], store, nil, flags) # VERIFY IT SO WE CAN PULL OUT THE DATA
      return pkcs7.data
    end

    # Checks to see if a givin certificate exists in the keychain by looking it
    # up by the name and SHA1
    #
    # @param common_name [String] common name used in the certificate
    # @param sha1 [String] SHA1 of the certificate
    # @return [Boolean]
    def cert_valid?(common_name, sha1)
      certs = `security find-certificate -c "#{common_name}" -Z -p -a`
      end_certificate = "-----END CERTIFICATE-----"
      state = :searching
      cert = ""

      certs.lines.each do |line|
        case state
          when :searching

            if line.include? sha1
              state = :found_hash
            end

          when :found_hash
            cert << line
          if line.include? end_certificate
            state = :did_end
          end
          when :did_end
        end
      end

      if cert.empty?
        throw 'Failed to find Signing Certificate'
      end

      File.open("pem", 'w') {|f| f.write(cert) }
      system("security verify-cert -c \"pem\"")
      File.unlink("pem")
      return $?.success?
    end

    # Returns a PList by parsing the provisioning profile at the given path
    #
    # @param path [String] path to plist to parse
    # @return [PList]
    def parse_provisioning_proflie(path)
      # Read provisioning profile into signedData
      signed_data=File.read(path)
      # Parse profile
      r = Plist::parse_xml(unwrap_signed_data(signed_data))
      return r
    end

    # Raises an exception if attributes needed for signing aren't set
    def validate_attributes
      if self.app_path.nil?
        raise 'app_path required to sign'
      end

      if self.provisioning_profile_path.nil?
        raise 'provisioning_profile_path required to sign'
      end

      if self.signing_identity.nil?
        raise 'signing_identity required to sign'
      end

      if self.signing_identity_SHA1.nil?
        raise 'signing_identity_SHA1 required to sign'
      end

      if self.generated_ipa_name.nil?
        raise 'generated_ipa_name required to sign'
      end
    end

    # Creates an ipa by using the signing information given in the set
    # attributes
    def sign

      validate_attributes

      # Parse profile
      r = parse_provisioning_proflie(self.provisioning_profile_path)

      # Grab entitlements
      entitlements=r['Entitlements']

      if self.bundle_id
        # Update info plist to have bundle id specified in the config
        info_plist_path="#{app_path}/Info.plist"
        system("plutil -convert xml1 \"#{info_plist_path}\"")
        file_data=File.read(info_plist_path)
        info_plist=Plist::parse_xml(file_data)
        info_plist['CFBundleIdentifier']=self.bundle_id

        # Save updated info plist and entitlements plist
        info_plist.save_plist info_plist_path
      end

      entitlements.save_plist("#{app_path}/Entitlements.plist")

      # Remove old embedded provisioning profile
      File.unlink("#{app_path}/embedded.mobileprovision") if File.exists? "#{app_path}/embedded.mobileprovision"

      # Embed new profile
      FileUtils.cp_r(self.provisioning_profile_path,"#{app_path}/embedded.mobileprovision")

      puts 'Verifying Signing Certificate'
      unless cert_valid?(self.signing_identity, self.signing_identity_SHA1)
        throw 'Failed to verify Signing Certificate'
      end
      puts 'Certificate Valid'

      # Resign application using correct profile and entitlements
      $stderr.puts "running /usr/bin/codesign -f -s \"#{self.signing_identity}\" --resource-rules=\"#{app_path}/ResourceRules.plist\" \"#{app_path}\""
      result=system("/usr/bin/codesign -f -s \"#{self.signing_identity_SHA1}\" --resource-rules=\"#{app_path}/ResourceRules.plist\" --entitlements=\"#{app_path}/Entitlements.plist\" \"#{app_path}\"")

      $stderr.puts "codesigning returned #{result}"
      throw 'Codesigning failed' if !result

      # Create temporary folder to zip up the application
      app_folder=Pathname.new(app_path).dirname.to_s
      temp_folder="#{app_folder}/temp_#{generated_ipa_name}"
      Dir.mkdir(temp_folder)
      Dir.mkdir("#{temp_folder}/Payload")
      FileUtils.cp_r(app_path,"#{temp_folder}/Payload")

      # Zip it up into the correct directory
      system("pushd \"#{temp_folder}\" && /usr/bin/zip -r \"../#{generated_ipa_name}.ipa\" Payload")

      # Remove temporary folder
      FileUtils.rm_rf(temp_folder)
    end

  end

end
