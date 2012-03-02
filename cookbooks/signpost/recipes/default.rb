# --- Install packages we need ---
%w{ntp liblwt-ssl-ocaml-dev liblwt-ocaml-dev ocaml-native-compilers libounit-ocaml-dev git ocaml-findlib build-essential libbitstring-ocaml-dev libocamlgraph-ocaml-dev oasis}.each do |pkg|
  package pkg do
    action :install
  end
end

# --- Get the signpost source ---
git "/usr/local/signpost" do
  repository "git://github.com/avsm/signpostd.git"
  reference "master"
  action :sync
end
