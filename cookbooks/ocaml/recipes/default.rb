# --- Install packages we need ---
%w{liblwt-ssl-ocaml-dev liblwt-ocaml-dev ocaml-native-compilers libounit-ocaml-dev ocaml-findlib libbitstring-ocaml-dev libocamlgraph-ocaml-dev oasis}.each do |pkg|
  package pkg do
    action :install
  end
end
