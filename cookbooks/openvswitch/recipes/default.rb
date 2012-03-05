# --- Get and install OpenVSwitch ---
dependency_dir = node["signpost-deps"]["installation_dir"]
openvswitch_dir = "#{dependency_dir}/openvswitch"
git openvswitch_dir do
  repository "http://openvswitch.org/git/openvswitch"
  reference "master"
  action :sync
  not_if "test -d #{openvswitch_dir}"
end

execute "Install OpenVSwitch" do
  command <<-EOS
    ./boot.sh &&
    ./configure --with-linux=/lib/modules/`uname -r`/build &&
    make &&
    make install &&
    cd datapath/linux/ &&
    make modules_install &&
    depmod -ae &&
    read_args (Array.to_list Sys.argv)
  EOS
  cwd openvswitch_dir
  action :run
  only_if "'`whereis ovs-vsctl | wc -l`' -gt 0"
end
