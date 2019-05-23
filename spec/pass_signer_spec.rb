require "pathname"
require "tmpdir"

RSpec.describe PassSigner do
  it "has a version number" do
    expect(PassSigner::VERSION).not_to be nil
  end

  it "compresses a valid pass into a pkpass" do
    Tempfile.create('pass-signing-tests/StoreCard.pass') do |output|
      signer = PassSigner.new(sample_store_pass_path.to_s, nil, nil, nil, output)
      signer.validate_directory_as_unsigned_raw_pass
      signer.create_temporary_directory
      signer.copy_pass_to_temporary_location
      signer.clean_ds_store_files
      signer.generate_json_manifest
      signer.compress_pass_file

      path_file = Pathname(output)
      expect(path_file.exist?).to be true
    end
  end
end
