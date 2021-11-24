require "spec_helper"
require "serverspec"

package = "icingaweb2"
service = "icingaweb2"
config  = "/etc/icingaweb2/icingaweb2.conf"
user    = "icingaweb2"
group   = "icingaweb2"
ports   = [PORTS]
log_dir = "/var/log/icingaweb2"
db_dir  = "/var/lib/icingaweb2"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/icingaweb2.conf"
  db_dir = "/var/db/icingaweb2"
end

describe package(package) do
  it { should be_installed }
end

describe file(config) do
  it { should be_file }
  its(:content) { should match Regexp.escape("icingaweb2") }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(db_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/icingaweb2") do
    it { should be_file }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
