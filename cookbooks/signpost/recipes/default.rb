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

execute "Compile and install Signpost" do
  command "make"
  cwd signpost_dir
  # Don't install if it has already been installed
  creates "#{signpost_dir}/installed"
  action :run
end


# --- Setup a signpost service ---
# template "#{node["bluepill"]["conf_dir"]}/signpost_server.pill" do
#   source "signpost_server.pill.erb"
# end
# service "signpost_server" do
#   provider bluepill_service
#   action [:enable, :load, :start]
# end
bluepill_service "signpost_server" do
  action [:enable, :load, :start]
end