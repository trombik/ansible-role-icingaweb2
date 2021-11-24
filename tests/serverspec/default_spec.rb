require "spec_helper"
require "serverspec"

package = case os[:family]
          when "freebsd"
            "icingaweb2-php74"
          else
            "icingaweb2"
          end
config_dir = case os[:family]
             when "freebsd"
               "/usr/local/etc/icingaweb2"
             else
               "/etc/icingaweb2"
             end
user    = "www"
group   = "www"
config_files = %w[
  authentication.ini
  config.ini
  groups.ini
  resources.ini
  roles.ini
  modules/monitoring/backends.ini
  modules/monitoring/commandtransports.ini
  modules/monitoring/config.ini
]
db_user = "icingaweb"
db_name = "icingaweb"
db_password = "password"
admin_user = "admin"

describe package(package) do
  it { should be_installed }
end

config_files.each do |f|
  describe file("#{config_dir}/#{f}") do
    it { should be_file }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    it { should be_mode 640 }
    its(:content) { should match(/Managed by ansible/) }
  end
end

# is the database empty?
describe command "env PGPASSWORD=#{db_password} psql --host 127.0.0.1 --user #{db_user} -c 'SELECT * FROM icingaweb_user' #{db_name}" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/name | active | password_hash | ctime | mtime/) }
end

# does the admin user exist?
describe command "env PGPASSWORD=#{db_password} psql --host 127.0.0.1 --user #{db_user} -c '\\x' -c 'SELECT * FROM icingaweb_user' #{db_name}" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/name\s+\|\s+#{admin_user}/) }
  its(:stdout) { should match(/active\s+\|\s+1/) }
  its(:stdout) { should match(/password_hash\s+\|\s+\\x[0-9a-z]+/) }
end
