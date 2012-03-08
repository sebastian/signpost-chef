# --- Setup a signpost service ---
conf_path = File.expand_path node["signpost"]["config_path"]
conf = YAML::load(File.open(conf_path))["config"]
node["iodine_password"] = conf["iodine_password"]

template "#{node["bluepill"]["conf_dir"]}/signpost_server.pill" do
  source "signpost_server.pill.erb"
end

bluepill_service "signpost_server" do
  action [:enable, :load, :start]
end
