# --- Setup a signpost service ---
conf_path = File.expand_path node["signpost"]["config_path"]
conf = YAML::load(File.open(conf_path))["config"]

template "#{node["bluepill"]["conf_dir"]}/signpost_server.pill" do
  source "signpost_server.pill.erb"
  variables(
    :install_dir => node["signpost"]["installation_dir"],
    :pid_dir => node["signpost"]["pid_dir"],
    :log_dir => node["signpost"]["log_dir"],
    :password => conf["iodine_password"],
    :ip_slash_24 => conf["ip_slash_24"],
    :signpost_number => conf["signpost_number"],
    :domain => conf["domain"]
  )
end

bluepill_service "signpost_server" do
  action [:enable, :load, :start]
end
