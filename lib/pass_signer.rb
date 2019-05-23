require "pass_signer/version"

class PassSigner
  class Error < StandardError; end

  attr_accessor :pass_url, :certificate_url, :certificate_password, :output_url, :compress_into_zip_file, :temporary_directory, :temporary_path, :manifest_url, :signature_url, :wwdr_intermediate_certificate_path

  def initialize(pass_url, certificate_url, certificate_password, wwdr_intermediate_certificate_path, output_url, compress_into_zip_file = true)
    self.pass_url                           = pass_url
    self.certificate_url                    = certificate_url
    self.certificate_password               = certificate_password
    self.wwdr_intermediate_certificate_path = wwdr_intermediate_certificate_path
    self.output_url                         = output_url
    self.compress_into_zip_file             = compress_into_zip_file
  end

  def sign_pass!(force_clean_raw_pass = false)
    # Validate that requested contents are not a signed and expanded pass archive.
    validate_directory_as_unsigned_raw_pass(force_clean_raw_pass)

    # Get a temporary place to stash the pass contents
    create_temporary_directory

    # Make a copy of the pass contents to the temporary folder
    copy_pass_to_temporary_location

    # Clean out the unneeded .DS_Store files
    clean_ds_store_files

    # Build the json manifest
    generate_json_manifest

    # Sign the manifest
    sign_manifest

    # Package pass
    compress_pass_file

    # Clean up the temp directory
    # self.delete_temp_dir
  end

  # private

  # Ensures that the raw pass directory does not contain signatures
  def validate_directory_as_unsigned_raw_pass(force_clean = false)
    force_clean_raw_pass if force_clean

    has_manifiest = File.exist?(File.join(pass_url, '/manifest.json'))
    puts "Raw pass has manifest? #{has_manifiest}"

    has_signiture = File.exist?(File.join(pass_url, '/signature'))
    puts "Raw pass has signature? #{has_signiture}"

    if has_signiture || has_manifiest
      raise "#{pass_url} contains pass signing artificats that need to be removed before signing."

    end
  end

  def force_clean_raw_pass
    puts 'Force cleaning the raw pass directory.'
    if File.exist?(File.join(pass_url, '/manifest.json'))
      File.delete(File.join(pass_url, '/manifest.json'))
    end

    if File.exist?(File.join(pass_url, '/signature'))
      File.delete(File.join(pass_url, '/signature'))
    end
  end

  # Creates a temporary place to work with the pass files without polluting the original
  def create_temporary_directory
    self.temporary_directory = Dir.mktmpdir
    puts "Creating temp dir at #{temporary_directory}"
    self.temporary_path = temporary_directory + '/' + pass_url.split('/').last

    # Check if the directory exists
    if File.directory?(temporary_path)
      # Need to clean up the directory
      FileUtils.rm_rf(temporary_path)
    end
  end

  # Copies the pass contents to the temporary location
  def copy_pass_to_temporary_location
    puts 'Copying pass to temp directory.'
    FileUtils.cp_r(pass_url, temporary_directory)
  end

  # Removes .DS_Store files if they exist
  def clean_ds_store_files
    puts 'Cleaning .DS_Store files'
    Dir.glob(temporary_path + '**/.DS_Store').each do |file|
      File.delete(file)
    end
  end

  # Creates a json manifest where each files contents has a SHA1 hash
  def generate_json_manifest
    puts 'Generating JSON manifest'
    manifest = {}
    # Gather all the files and generate a sha1 hash
    Dir.glob(temporary_path + '/**').each do |file|
      manifest[File.basename(file)] = Digest::SHA1.hexdigest(File.read(file))
    end

    # Write the hash dictionary out to a manifest file
    self.manifest_url = temporary_path + '/manifest.json'
    File.open(manifest_url, 'w') do |f|
      f.write(manifest.to_json)
    end
  end

  def sign_manifest
    puts 'Signing the manifest'
    # Import the certificates
    p12_certificate = OpenSSL::PKCS12.new(File.read(certificate_url), certificate_password)
    wwdr_certificate = OpenSSL::X509::Certificate.new(File.read(wwdr_intermediate_certificate_path))

    # Sign the data
    flag = OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
    signed = OpenSSL::PKCS7.sign(p12_certificate.certificate, p12_certificate.key, File.read(manifest_url), [wwdr_certificate], flag)

    # Create an output path for the signed data
    self.signature_url = temporary_path + '/signature'

    # Write out the data
    File.open(signature_url, 'w') do |f|
      f.syswrite signed.to_der
    end
  end

  def compress_pass_file
    puts 'Compressing the pass'
    zipped_file = File.open(output_url, 'w')

    Zip::OutputStream.open(zipped_file.path) do |z|
      Dir.glob(temporary_path + '/**').each do |file|
        z.put_next_entry(File.basename(file))
        z.print IO.read(file)
      end
    end
    zipped_file
  end

  def delete_temp_dir
    FileUtils.rm_rf(temporary_path)
  end
end
