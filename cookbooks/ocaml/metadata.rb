maintainer        "Signpost team"
maintainer_email  "sebastian.probst.eide@gmail.com"
license           "Apache 2.0"
description       "Installs OpenVSwitch"
version           "0.0.1"
recipe            "ocaml", "Installs OCaml"
recipe            "ocaml::signpost", "Install Signpost specific OCaml libraries"

%w{ ubuntu debian arch}.each do |os|
  supports os
end

%w{ apt build-essential git }.each do |cb|
  depends cb
end
