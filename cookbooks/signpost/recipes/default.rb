# --- We need to install iodine ---
package "iodine" do
  action :install
end

# --- Get the signpost source ---
signpost_dir = node["signpost"]["installation_dir"]

# --- Create source directories ---
signpost = node["signpost"]
[signpost["log_dir"], signpost["pid_dir"], signpost["installation_dir"]].each do |sp_dir|
  directory sp_dir do
    mode "0755"
    action :create
    recursive true
  end
end

# --- Get and compile the signpost source ---
signpost = node["signpost"]
git signpost_dir do
  repository "git://github.com/avsm/signpostd.git"
  reference "master"
  action :sync
end

# We want to replace the configuration file with one
# that has configuration values as specified by the user
conf = YAML::load(File.open('/tmp/config.yaml'))["config"]

template "#{signpost_dir}/lib/config.ml" do
  source "config.ml.erb"
  variables(
    :user => conf["user"],
    :signpost_number => conf["signpost_number"],
    :domain => conf["domain"],
    :external_ip => conf["external_ip"],
    :external_dns => conf["external_dns"],
  )
end

execute "Compile and install Signpost" do
  command "make"
  cwd signpost_dir
  # Don't install if it has already been installed
  creates "#{signpost_dir}/installed"
  action :run
end

# --- Setup a signpost service ---
node["iodine_password"] = conf["iodine_password"]

template "#{node["bluepill"]["conf_dir"]}/signpost_server.pill" do
  source "signpost_server.pill.erb"
end

bluepill_service "signpost_server" do
  action [:enable, :load, :start]
end
